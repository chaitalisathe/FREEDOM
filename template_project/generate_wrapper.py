# Import necessary libraries/modules
import os
import sys
import re

# Define functions
def read_file(file_path):
    """
    Reads the content of a file and returns it as a string.

    Parameters:
        file_path (str): The path to the file.

    Returns:
        str: The content of the file.
    """
    try:
        with open(file_path, "r", encoding="utf-8") as file:
            return file.read()
    except FileNotFoundError:
        print(f"Error: The file '{file_path}' does not exist.")
        return ""
    except Exception as e:
        print(f"Error reading file: {e}")
        return ""

def write_to_file(filename, content):
    """
    Writes the given content to a file.

    Args:
        filename (str): The name of the file to write to.
        content (str): The content to write.

    Returns:
        None
    """
    with open(filename, "w") as file:
        file.write(content)

def extract_module_io(module_def):
    """
    Extracts the input and output signal names from a Verilog module definition.

    Args:
        module_def (str): A Verilog module definition as a string.

    Returns:
        tuple: Two lists, the first containing input signal names and the second containing output signal names.
    """
    # List to hold the names of input and output signals.
    input_signals = []
    output_signals = []
    
    # Regular expression to match lines starting with 'input' or 'output'
    # This pattern will capture the direction (input/output) and the remainder of the declaration up to the semicolon.
    # It uses MULTILINE so that ^ matches the start of a line.
    pattern = re.compile(r'^\s*(input|output)\s+(.*?);', re.MULTILINE)
    
    # Iterate over all matches
    for match in pattern.finditer(module_def):
        direction = match.group(1)   # "input" or "output"
        decl = match.group(2).strip()  # The rest of the line containing the signal declarations
        
        # Split the declaration by commas to get individual signal names
        signals = [signal.strip() for signal in decl.split(',') if signal.strip()]
        
        if direction == "input":
            input_signals += signals
        elif direction == "output":
            output_signals += signals
    
    return input_signals, output_signals


def create_list(input_list):
    """
    Extracts the values inside square brackets from a list of Verilog port strings
    and returns a list where each element is tuple of (port name, bitwidth - 1)
    
    Args:
        input_list (list): List of Verilog port strings with array indices.
    
    Returns:
        list: A list conatining tuples of (port name, bitwidth)
    """
    # Regular expression to capture values inside square brackets
    pattern = r"\[(.*?)\]"  # Non-greedy match for any characters inside brackets
    
    port_lst = []
    
    for item in input_list:
        # Find the value inside the brackets
        match = re.search(pattern, item)
        if match:
            port_name = item.replace(match.group(0), '')  # Remove brackets from the port name
            port_value = match.group(1)  # Extract the value inside the brackets
            port_lst.append((port_name.strip(),int(port_value.split(':')[0].strip()) + 1))  # Map port name to the extracted value
        else:
            port_name = item
            port_lst.append((port_name.strip(),1))
    
    return port_lst


def substitute_string(text, old_string, new_string):
    """
    Replaces all occurrences of old_string with new_string in the given text.

    Args:
        text (str): The input text.
        old_string (str): The string to be replaced.
        new_string (str): The replacement string.

    Returns:
        str: The modified text with substitutions.
    """
    return re.sub(re.escape(old_string), new_string, text)


def create_dut_instance(flnm, inps_w, outs_w, ex_sigs):
    """
    Function description goes here 
    """
    # Index tracking variables and port lists
    upper_index = 0
    lower_index = 0
    inp_lst     = []
    out_lst     = [] 

    # Handle inputs 
    for inp in inps_w:
        if inp[0] in ex_sigs:
            continue
        else:
            upper_index = inp[1] + lower_index
            inp_lst.append('.{0}(shared_input[{1}:{2}])'.format(inp[0], upper_index-1, lower_index))
            lower_index = upper_index
    
    # Reset indexes
    upper_index = 0
    lower_index = 0

    # Handle outputs
    for outs in outs_w:
        if outs[0] in ex_sigs:
            continue
        else:
            upper_index = outs[1] + lower_index
            out_lst.append('.{0}(design_output[{1}:{2}])'.format(outs[0], upper_index-1, lower_index))
            lower_index = upper_index

    dut_str = """

{0} EMULATOR_DUT (
.f_op_clk (fpga_op_clk) ,
.f_prog_clk(fpga_prog_clk), 
.f_reset(fpga_reset) ,
.f_ccff_head(ccff_head),
.f_ccff_tail(ccff_tail),
{1},
{2}
);

""".format('asic_fpga_' + flnm,',\n'.join(inp_lst),',\n'.join(out_lst))
    
    return dut_str


def main():
    # Read command line args
    top_mod_name  = sys.argv[1]
    template_name = 'asic_fpga_benchmark_top.v'

    # Read files
    template = read_file(template_name)
    top_mod  = read_file('./hardware/' + 'asic_fpga_' + top_mod_name +'.v')

    # Extract inputs and outputs
    inps, outs = extract_module_io(top_mod)

    # Create lists mapping signals and bitwidths -1
    inps_w = create_list(inps)
    outs_w = create_list(outs)

    # Excluded signals
    ex_sigs = ['clk', 'f_prog_clk', 'f_reset', 'f_ccff_head','f_ccff_tail', 'rst', 'f_op_clk']

    # Generate Instatiation
    ins_str = create_dut_instance(top_mod_name,inps_w,outs_w,ex_sigs)

    quart_wrapper = substitute_string(template, '---------Instantiate asic_fpga_benchmark module here----------', ins_str)
    quart_wrapper = substitute_string(quart_wrapper, 'benchmark', top_mod_name)

    write_to_file('asic_fpga_' + top_mod_name + '_top.v', quart_wrapper)


if __name__ == "__main__":
    main()