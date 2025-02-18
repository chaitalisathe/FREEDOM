# Import necessary libraries/modules
import sys
import re
import os

# Define functions
def extract_verilog_instance(verilog_text, module_name):
    """
    Extracts a specific module instantiation from Verilog code.

    Args:
        verilog_text (str): The full Verilog code as a string.
        module_name (str): The name of the module to extract.

    Returns:
        str: The extracted module instantiation, or an empty string if not found.
    """
    # Regular expression pattern to match the full module instantiation
    pattern = rf"\b{module_name}\s+\w+\s*\(([\s\S]*?)\);\s*"  

    # Search for the module instantiation
    match = re.search(pattern, verilog_text, re.MULTILINE)

    if match:
        return f"{match.group()});"  # Return the full match
    else:
        return ""  # Return empty string if module instantiation is not found
    
    
def extract_ports(instantiation):
    """
    Extracts ports and their connections from a Verilog module instantiation.

    Args:
        instantiation (str): The Verilog instantiation string.

    Returns:
        list: A list of tuples where each tuple contains the port name and its connection.
    """
    # Regular expression to capture the port names and connections (including arrays)
    pattern = r"(\w+\[\d*[:]*\d*\]?)"  # Matches ports like prog_clk[0], set[0], gfpga_pad_GPIO_PAD[0:31]

    # Find all matches in the instantiation string
    ports = re.findall(pattern, instantiation)

    # Format the ports as '.port_name(connection)' (optional: strip whitespace)
    formatted_ports = [port.strip() for port in ports]

    return formatted_ports  # Return the extracted port names as a list


def create_dict(input_list):
    """
    Extracts the values inside square brackets from a list of Verilog port strings
    and returns a dictionary mapping port names to their respective values inside the brackets.
    
    Args:
        input_list (list): List of Verilog port strings with array indices.
    
    Returns:
        dict: A dictionary where the keys are the port names and the values are the values inside square brackets.
    """
    # Regular expression to capture values inside square brackets
    pattern = r"\[(.*?)\]"  # Non-greedy match for any characters inside brackets
    
    port_dict = {}
    
    for item in input_list:
        # Find the value inside the brackets
        match = re.search(pattern, item)
        if match:
            port_name = item.replace(match.group(0), '')  # Remove brackets from the port name
            port_value = match.group(1)  # Extract the value inside the brackets
            port_dict[port_name] = port_value  # Map port name to the extracted value
    
    return port_dict


def extract_assignment_lines(input_string, in_str):
    """
    Extracts lines from a string that contain both '=' and in_str.
    
    Args:
        input_string (str): The input string containing multiple lines.
    
    Returns:
        list: A list of lines containing both '=' and in_str.
    """
    # Split the input string into lines
    lines = input_string.splitlines()
    
    # Filter lines that contain both '=' and in_str
    filtered_lines = [line.strip() for line in lines if '=' in line and in_str in line]
    
    return filtered_lines


def extract_number_between_underscores(input_string):
    """
    Extracts the number between two underscores in the given string.
    
    Args:
        input_string (str): The input string containing underscores and numbers.
    
    Returns:
        str or None: The extracted number as a string, or None if no match is found.
    """
    match = re.search(r'_(\d+)__', input_string)  # Find a number between underscores
    return match.group(1) if match else None  # Return the number if found

def get_ports_index(ports,in_str):
    for index in range(len(ports)):
        if ports[index][0] in in_str:
            return index
    return -1


def instantiate_dut(assignments, always_assignments, dict, gpio):
    """
    """
    dut_str = 'wire [{0}] {1};\n'.format(dict[gpio],gpio)
    dut_str += """

fpga_top FPGA_DUT (.prog_clk(f_prog_clk),
.set(1'b0),
.reset(f_reset),
.clk(f_op_clk),
.{0}({1}[{2}]),
.ccff_head(f_ccff_head),
.ccff_tail(f_ccff_tail));

""".format(gpio,gpio,dict[gpio])

    dut_str += '\n'.join(assignments)

    always_str = """

\nalways@(*)
begin
{0}
end

""".format('\n'.join(always_assignments))
    
    dut_str += always_str

    return dut_str


def extract_top_module(verilog_code, start_pragma, end_pragma):
    """
    Extracts the top module from a given list of modules. Top module is the module that Contains the pragmas
    
    Args:
        verilog_code (list): The input list containing Verilog modules.
    
    Returns:
        str or None: The extracted module as a string, or None if no module is found.
    """

    for module in verilog_code:
        if start_pragma in module and end_pragma in module:
            return module 
    return None


def extract_code_between(text, start_word, end_word):
    """
    Extracts all content between two given words in a string.

    Args:
        text (str): The input string.
        start_word (str): The starting word.
        end_word (str): The ending word.

    Returns:
        str: The extracted content between the words.
    """
    # Regular expression to capture content between start_word and end_word
    pattern = rf"{re.escape(start_word)}(.*?){re.escape(end_word)}"
    
    match = re.search(pattern, text, re.DOTALL)  # re.DOTALL allows matching across multiple lines
    
    return match.group(1).strip() if match else ""


def add_io_ports_to_verilog(module_str):
    """
    Adds the following I/O ports to a Verilog module:
        input      f_prog_clk;
        input      f_reset;
        input      f_ccff_head;
        output     f_ccff_tail;

    The new ports will be added:
      1. Inside the module port list (inside `module (...)`).
      2. After the last I/O declaration.

    Args:
        module_str (str): The Verilog module as a string.

    Returns:
        str: The modified Verilog module with the new ports added.
    """
    # Define the new ports to be added
    new_port_names = ["f_prog_clk", "f_reset", "f_ccff_head", "f_ccff_tail", "f_op_clk"]
    new_ports_definitions = [
        "input      f_prog_clk;",  
        "input      f_reset;",  
        "input      f_ccff_head;",
        "input      f_op_clk;",  
        "output     f_ccff_tail;"
    ]

    # Step 1: Modify the port list inside `module (...)`
    module_match = re.search(r'(module\s+\w+\s*\(\s*)([^)]+)(\s*\))', module_str, re.MULTILINE)
    
    if module_match:
        module_start, port_list, module_end = module_match.groups()
        
        # Append new ports to the existing port list
        updated_port_list = port_list.strip() + ", " + ", ".join(new_port_names)
        
        # Replace the module declaration with the updated port list
        module_str = re.sub(r'(module\s+\w+\s*\(\s*)[^)]+(\s*\))', module_start + updated_port_list + module_end, module_str, count=1)

    # Step 2: Add new I/O definitions after the last I/O declaration
    io_match = re.search(r'(output\s+[^;]+;)(?![\s\S]*\binput\b|\boutput\b)', module_str, re.MULTILINE)

    if io_match:
        insert_pos = io_match.end()  # Insert after the last I/O declaration
        module_str = module_str[:insert_pos] + "\n" + "\n".join(new_ports_definitions) + module_str[insert_pos:]

    return module_str  # Return the modified module


def extract_ports_connections(instantiation_str):
    """
    Extracts the ports and their connections from a Verilog module instantiation.

    Args:
        instantiation_str (str): A Verilog module instantiation string.

    Returns:
        list: A 2D list where each sublist contains [port_name, connected_signal].
    """
    # Regular expression to match .port_name(signal_name)
    matches = re.findall(r'\.(\w+)\s*\(\s*([\w\[\]:]+)\s*\)', instantiation_str)

    # Convert matches to a 2D list
    return [list(match) for match in matches]

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


def extract_modules(verilog_code):
    """
    Extracts all Verilog modules from the given Verilog code and returns them in a list.

    Args:
        verilog_code (str): The Verilog code as a string.

    Returns:
        list: A list of strings, each containing the Verilog code for a module.
    """
    # Regular expression to match a Verilog module (between `module` and `endmodule`)
    module_pattern = r'\bmodule\b[\s\S]*?\bendmodule\b'
    
    # Use re.findall to extract all modules matching the pattern
    modules = re.findall(module_pattern, verilog_code)

    return modules

def delete_file(file_path):
    """
    Deletes the specified file if it exists.

    Parameters:
        file_path (str): The path to the file to be deleted.

    Returns:
        bool: True if the file was deleted, False if it did not exist.
    """
    try:
        if os.path.exists(file_path):
            os.remove(file_path)
            return True
        else:
            print(f"File '{file_path}' does not exist.")
            return False
    except Exception as e:
        print(f"Error deleting file: {e}")
        return False
    
def rename_verilog_module(verilog_code, new_name):
    # Regular expression to match the module definition
    module_pattern = r"(\bmodule\s+)(\w+)"
    
    # Replace the module name with the new name
    renamed_code = re.sub(module_pattern, r"\1" + new_name, verilog_code, count=1)
    
    return renamed_code

def extract_always_code(verilog_code):
    """
    Extracts the code inside always blocks from a Verilog code snippet.
    Assumes that every always block contains a 'begin' and 'end' pair.
    
    Args:
        verilog_code (str): The Verilog code as a string.
    
    Returns:
        str: A string containing the code inside an always block.
    """
    # Regex pattern explanation:
    # (?s)          : Enable DOTALL mode so that '.' matches newline characters.
    # always\s*@   : Matches the literal 'always @' (with possible whitespace in between).
    # .*?          : Lazily match any characters up to the first occurrence of 'begin'.
    # begin        : Matches the literal 'begin'.
    # (.*?)        : Lazily capture everything up to the first 'end'.
    # end          : Matches the literal 'end'.
    pattern = r'(?s)always\s*@.*?begin(.*?)end'
    
    # Find all matches and strip any leading/trailing whitespace from each captured group.
    always_contents = [match.strip() for match in re.findall(pattern, verilog_code)]
    
    return ("\n").join(always_contents)

def extract_first_module(verilog_code):
    """
    Extracts the first Verilog module definition from a given Verilog code string.

    Args:
        verilog_code (str): The Verilog code as a string.

    Returns:
        str: The extracted module definition including its ports and body, or an empty string if not found.
    """
    # Regex pattern explanation:
    # - module\s+(\w+)  : Matches 'module' followed by whitespace and captures the module name.
    # - \(.*?\)         : Lazily captures everything inside the module parameter list (handles multi-line cases).
    # - .*?             : Lazily captures the module body.
    # - endmodule       : Matches the 'endmodule' keyword.
    pattern = r'(?s)module\s+\w+\s*\(.*?\)\s*;.*?endmodule'
    
    match = re.search(pattern, verilog_code)
    return match.group(0) if match else ""

def extract_assigned_variables(verilog_code):
    """
    Extracts all assigned variables from a Verilog code snippet, 
    including always blocks, and case statements.

    Args:
        verilog_code (str): The Verilog code as a string.

    Returns:
        set: A set of unique assigned variable names.
    """
    assigned_vars = set()
    
    # Pattern to match assignments in always blocks and case statements
    always_pattern = r'(?<!\w)(\w+)\s*(?:=|<=)(?!=)'  # Captures variable before = or <=, but not ==

    # Find all matches in the Verilog code
    assigned_vars.update(re.findall(always_pattern, verilog_code))

    return assigned_vars

# Main script logic
def main():
    # Parse command-line arguments
    flnm       = sys.argv[1]
    inter_filename  = flnm + "_instantiated.v"
    redacted_filename = flnm + "_redacted.v"
    tesbench_filename  = "./hardware/SRC/" + flnm + "_redacted_autocheck_top_tb.v"
    fpga_gpio = "gfpga_pad_GPIO_PAD"
    startpragma = sys.argv[2]
    endpragma = sys.argv[3]
    
    # Read FPGA testbench
    file = open(tesbench_filename, "r")
    testbench_content = file.read()
    file.close()

    # Read redacted file
    file = open(redacted_filename, "r")
    redact_content = file.read()
    file.close()

    # Read intermediate file
    file = open(inter_filename, "r")
    inter_content = file.read()
    file.close()

    # Extract top module and add io
    ver_modules = extract_modules(inter_content)
    top_mod = extract_top_module(ver_modules, startpragma, endpragma)
    new_top = add_io_ports_to_verilog(top_mod)

    # Extract ports and connections between pragmas
    ports = extract_ports_connections(extract_code_between(top_mod, startpragma, endpragma).replace('//',''))

    # Get DUT instance and ports (Testbench)
    dut             = extract_verilog_instance(testbench_content,'fpga_top')
    port_dict       = create_dict(extract_ports(dut))
    assignments     = extract_assignment_lines(testbench_content,fpga_gpio)
    new_assignments = []
    always_assignments = []

    # Extract reg variables from redaction
    reg_vars = extract_assigned_variables(extract_always_code(extract_first_module(redact_content)))

    # Extract GPIO assignments from testbench
    for assignment in assignments:
        lval, rval = assignment.split('=')
        lval, rval = lval.strip(), rval.strip()
        if fpga_gpio in lval:
            # Handle assignment to FPGA pins
            port_idx = get_ports_index(ports, rval)
            if (port_idx>=0):
                num = extract_number_between_underscores(rval)
                if (num):
                    new_assignments.append(lval + ' = ' + '(f_reset) ? 1\'bz: ' + ports[port_idx][1] + '[' + num + ']' + ';')
                else:
                    new_assignments.append(lval + ' = ' + '(f_reset) ? 1\'bz: ' + ports[port_idx][1] + ';')
        elif fpga_gpio in rval:
            # Handle assignment from FPGA pins
            port_idx = get_ports_index(ports, lval)
            if (port_idx >=0):
                num = extract_number_between_underscores(lval)
                if (num):
                    if ports[port_idx][1] in reg_vars:
                        always_assignments.append(ports[port_idx][1] + '[' + num + ']' + ' = ' + rval)
                    else:
                        new_assignments.append('assign ' + ports[port_idx][1] + '[' + num + ']' + ' = ' + rval)
                else:
                    if ports[port_idx][1] in reg_vars:
                        always_assignments.append(ports[port_idx][1] + ' = ' + rval)
                    else:
                        new_assignments.append('assign ' + ports[port_idx][1] + ' = ' + rval)

    dut_instance = instantiate_dut(new_assignments, always_assignments, port_dict, fpga_gpio)

    # Start Stitching process
    new_top = substitute_string(new_top, endpragma, dut_instance)           # Instantiate FPGA DUT and remove end pragma
    new_top = substitute_string(new_top,startpragma,'')                     # Remove start pragma
    new_top = rename_verilog_module(new_top,'asic_fpga_' + flnm)
    write_to_file('./hardware/'+'asic_fpga_' + flnm +'.v', new_top)

    # Write other module definitions into seperate file
    other_mods = []
    for mod in ver_modules:
        if mod != top_mod:
            other_mods.append(mod)
    write_to_file('./hardware/' + flnm + '_modules_lib.v', '\n\n'.join(other_mods))

    # Delete intermediate redact file
    #delete_file('./' + inter_filename)


# Entry point for the script
if __name__ == "__main__":
    main()
