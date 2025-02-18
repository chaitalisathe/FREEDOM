# Import necessary libraries/modules
import sys
import re

# Define functions
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


def extract_assigned_variables(verilog_code):
    """
    Extracts all assigned variables from a Verilog code snippet, 
    including assign statements, always blocks, and case statements.

    Args:
        verilog_code (str): The Verilog code as a string.

    Returns:
        set: A set of unique assigned variable names.
    """
    assigned_vars = set()

    # Pattern to match `assign var = ...;`
    assign_pattern = r'\bassign\s+(\w+)\s*='
    
    # Pattern to match assignments in always blocks and case statements
    always_pattern = r'(?<!\w)(\w+)\s*(?:=|<=)(?!=)'  # Captures variable before = or <=, but not ==

    # Find all matches in the Verilog code
    assigned_vars.update(re.findall(assign_pattern, verilog_code))
    assigned_vars.update(re.findall(always_pattern, verilog_code))

    return assigned_vars


def extract_rhs_variables(verilog_code):
    """
    Extracts all right-hand side (RHS) variables from a Verilog code snippet.
    Ignores constants (numeric, hex, and binary literals) and sensitivity list items.

    Args:
        verilog_code (str): The Verilog code as a string.

    Returns:
        set: A set of unique RHS variable names.
    """
    rhs_vars = set()

    # Remove single-line comments (// ...)
    verilog_code = re.sub(r'//.*', '', verilog_code)

    # Regex to match assignment expressions (both blocking and non-blocking)
    assignment_pattern = r'(?<!\w)(\w+)\s*(?:=|<=)\s*(.*?);'
    
    # Extract RHS expressions
    procedural_matches = re.findall(assignment_pattern, verilog_code, re.DOTALL)
    procedural_expressions = [match[1] for match in procedural_matches]

    # Regex pattern to extract valid variable names (ignores numbers, hex, and binary constants)
    variable_pattern = r'\b[a-zA-Z_]\w*\b'

    for expr in procedural_expressions:
        # Remove constants (hex, binary, decimal numbers)
        expr = re.sub(r"\b\d+'[bhd][0-9a-fA-F_xz]+\b", "", expr)  # Remove Verilog literals (e.g., 13'h0000)
        expr = re.sub(r"\b\d+\b", "", expr)  # Remove standalone numbers

        # Extract variable names
        variables = re.findall(variable_pattern, expr)
        rhs_vars.update(variables)

    return rhs_vars


def generate_verilog_module(module_name, inputs, outputs, mod_body):
    """
    Generates a Verilog module definition given inputs, outputs, and a module name.

    Args:
        module_name (str): The name of the Verilog module.
        inputs (set): A set of input signal names.
        outputs (set): A set of output signal names.

    Returns:
        str: The Verilog module definition as a formatted string.
    """
    # Convert sets to sorted lists for consistent ordering
    inputs = sorted(inputs)
    outputs = sorted(outputs)

    # Create the module port list
    ports = inputs + outputs
    port_list = ", ".join(ports)

    # Construct the module definition
    verilog_code = f"module {module_name} ({port_list});\n\n"

    # Declare inputs
    for inp in inputs:
        verilog_code += f"input {inp};\n"

    # Declare outputs
    for out in outputs:
        verilog_code += f"output {out};\n"

    # Module body 
    verilog_code += "\n// Module implementation\n{0}\nendmodule".format(mod_body)

    return verilog_code


def extract_module_names_all(verilog_code):
    """
    Extracts all module names defined in a Verilog code snippet.

    Args:
        verilog_code (str): The Verilog code as a string.

    Returns:
        set: A set of unique module names.
    """
    # Regular expression to match module definitions
    module_pattern = re.findall(r'\bmodule\s+(\w+)\s*\(', verilog_code)

    return set(module_pattern) 


def extract_ports_connections(instantiation_str):
    """
    Extracts the ports and their connections from a Verilog module instantiation.

    Args:
        instantiation_str (str): A Verilog module instantiation string.

    Returns:
        dict: A dictionary where the key is the port name, and the value is the connected signal.
    """
    # Regular expression to match .port_name(signal_name)
    matches = re.findall(r'\.(\w+)\s*\(\s*([\w\[\]:]+)\s*\)', instantiation_str)

    # Convert matches to a dictionary
    return {match[0]: match[1] for match in matches}


def find_module_definition(verilog_code, module_name):
    """
    Finds and returns the definition of a specific module in a Verilog code string.

    Args:
        verilog_code (str): The full Verilog code as a string.
        module_name (str): The name of the module to find.

    Returns:
        str or None: The full module definition (from 'module' to 'endmodule') if found,
                     otherwise None.
    """
    # Build a regex pattern to capture the module definition.
    pattern = r'\bmodule\s+' + re.escape(module_name) + r'\b[\s\S]*?\bendmodule\b'
    
    match = re.search(pattern, verilog_code, re.IGNORECASE)
    
    return match.group(0) if match else None


def extract_module_io(module_def):
    """
    Extracts the input and output signal names from a Verilog module definition.

    Args:
        module_def (str): A Verilog module definition as a string.

    Returns:
        tuple: Two sets, the first containing input signal names and the second containing output signal names.
    """
    # Sets to hold the names of input and output signals.
    input_signals = set()
    output_signals = set()
    
    # Regular expression to match lines starting with 'input' or 'output'
    # This pattern will capture the direction (input/output) and the remainder of the declaration up to the semicolon.
    # It uses MULTILINE so that ^ matches the start of a line.
    pattern = re.compile(r'^\s*(input|output)\s+(.*?);', re.MULTILINE)
    
    # Iterate over all matches
    for match in pattern.finditer(module_def):
        direction = match.group(1)   # "input" or "output"
        decl = match.group(2).strip()  # The rest of the line containing the signal declarations
        
        # Remove any vector ranges, e.g., [15:0]
        decl = re.sub(r'\[[^\]]+\]', '', decl)
        
        # Split the declaration by commas to get individual signal names
        signals = [signal.strip() for signal in decl.split(',') if signal.strip()]
        
        if direction == "input":
            input_signals.update(signals)
        elif direction == "output":
            output_signals.update(signals)
    
    return input_signals, output_signals

def extract_signal_width(verilog_code, signal_name):
    """
    Extracts the signal width (including the vector range in square brackets)
    for a given signal name from a Verilog code string.
    
    The function looks for a declaration line where the signal is declared
    (using keywords such as input, output, wire, or reg) and captures the
    optional vector range preceding the signal name.

    Args:
        verilog_code (str): The Verilog code as a string.
        signal_name (str): The name of the signal to extract the width for.

    Returns:
        str: The vector range (e.g., "[15:0]") if found; otherwise, an empty string.
    """
    # Build a regular expression pattern.
    pattern = r'\b(?:input|output|wire|reg)\s*(\[[^\]]+\])?\s*' + re.escape(signal_name) + r'\b'
    
    match = re.search(pattern, verilog_code)
    if match:
        # If a vector range was captured, return it; otherwise, return an empty string.
        return match.group(1) if match.group(1) is not None else ""
    return ""

def remove_line_comments(verilog_code):
    """
    Removes all line comments (// ...) from a Verilog code snippet.

    Args:
        verilog_code (str): The Verilog code as a string.

    Returns:
        str: The Verilog code without line comments.
    """
    return re.sub(r'//.*', '', verilog_code)

def extract_module_instances(verilog_code, module_names):
    """
    Extracts instances of specific module names from a Verilog code snippet.

    Args:
        verilog_code (str): The Verilog code as a string.
        module_names (set): A set of module names to extract instances for.

    Returns:
        list: A list of module instantiation strings.
    """
    instances = []

    # Construct regex pattern dynamically for all module names
    module_pattern = r'\b(' + '|'.join(re.escape(name) for name in module_names) + r')\s+\w+\s*\([\s\S]*?\);'

    # Find all matches and store them in the list
    matches = re.findall(module_pattern, verilog_code)
    
    for match in matches:
        full_instance = re.search(rf'\b{match}\s+\w+\s*\([\s\S]*?\);', verilog_code)
        if full_instance:
            instances.append(full_instance.group().strip())

    return instances

def create_module_definition(module_name, input_ports, output_ports, mod_body):
    """
    Creates a Verilog module definition from input and output ports.

    Args:
        module_name (str): The name of the module.
        input_ports (set): A set of tuples containing input port names and widths.
        output_ports (set): A set of tuples containing output port names and widths.

    Returns:
        str: A Verilog module definition as a string.
    """
    # Prepare the input and output port declarations
    input_declarations = [f"input {width} {port};" for port, width in input_ports]
    output_declarations = [f"output {width} {port};" for port, width in output_ports]

    # Combine all port declarations
    all_declarations = input_declarations + output_declarations

    # Combine all ports in the module declaration for the list
    all_ports = [f"{port}" for port, _ in input_ports] + [f"{port}" for port, _ in output_ports]

    # Create the module definition
    module_definition = f"module {module_name} (\n" + ",\n".join([f"    {port}" for port in all_ports]) + "\n);\n"
    module_definition += "\n".join(all_declarations) + "\n" + mod_body + "\nendmodule"

    return module_definition

def extract_condition_signals(verilog_code):
    """
    Extracts all signals between 'if', 'else if', and 'case' conditions in a Verilog code snippet.

    Args:
        verilog_code (str): The Verilog code as a string.

    Returns:
        set: A set of unique signals found in the condition expressions.
    """
    signals = set()
    
    # Regular expression to match conditions inside 'if', 'else if', and 'case'
    pattern = r'\bif\s*\((.*?)\)|\belse\s+if\s*\((.*?)\)|\bcase\s*\((.*?)\)'

    # Find all matches
    matches = re.findall(pattern, verilog_code)

    # Extract signals from matched conditions
    for match in matches:
        for condition in match:
            if condition:  # Ignore empty matches
                found_signals = re.findall(r'\b[a-zA-Z_]\w*\b', condition)  # Extract signal names
                signals.update(found_signals)

    return signals

def create_module_instantiation(module_name, input_ports, output_ports):
    """
    Creates a Verilog module instantiation based on the input and output ports provided.

    Args:
        module_name (str): The name of the Verilog module.
        input_ports (set): A set containing tuples (port_name, width) for input ports.
        output_ports (set): A set containing tuples (port_name, width) for output ports.

    Returns:
        str: A Verilog module instantiation string.
    """
    # Create the input port declarations and connections
    input_declarations = [f".{port}({port})" for port, _ in input_ports]
    
    # Create the output port declarations and connections
    output_declarations = [f".{port}({port})" for port, _ in output_ports]

    # Combine input and output port declarations
    all_ports = input_declarations + output_declarations

    # Generate the module instantiation
    instantiation_str = f"{module_name} {module_name}_inst (" + ", ".join(all_ports) + ");"

    return instantiation_str

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


def extract_module_definitions(module_names, verilog_code):
    """
    Extracts all module definitions from a Verilog code string given a set of module names.

    Args:
        module_names (set): A set of module names to extract.
        verilog_code (str): The Verilog code as a string.

    Returns:
        list: A list of strings, where each string is a full module definition.
    """
    module_definitions = []
    
    # Regex pattern to match module definitions
    pattern = r'\bmodule\s+(\w+)\b[\s\S]*?\bendmodule\b'
    
    # Find all module definitions
    matches = re.findall(pattern, verilog_code)

    for match in matches:
        module_name = match
        if module_name in module_names:
            # Extract full module definition
            module_pattern = rf'\bmodule\s+{re.escape(module_name)}\b[\s\S]*?\bendmodule\b'
            module_match = re.search(module_pattern, verilog_code)
            if module_match:
                module_definitions.append(module_match.group())

    return module_definitions


# Main script logic
def main():
    # Parse command-line arguments (if any)
    flnm       = sys.argv[1]
    start_prag  = sys.argv[2]
    end_prag    = sys.argv[3]

    
    # Open File
    orig_file = open(flnm + '.v', "r")
    orig_content = orig_file.read()
    orig_file.close()


    # Extract code between pragmas
    code_snippet = extract_code_between(orig_content, start_prag, end_prag)
    code_snippet = remove_line_comments(code_snippet)
    orig_content = remove_line_comments(orig_content)

    # Hangle assignments and conditions
    outputs = extract_assigned_variables(code_snippet)
    inputs =  extract_rhs_variables(code_snippet)
    conditional_signals = extract_condition_signals(code_snippet)
    for c in conditional_signals:
        inputs.add(c)
    inputs_w  = set()
    outputs_w = set()
    for signal in inputs:
        if signal in outputs:
            continue
        width = extract_signal_width(orig_content, signal)
        inputs_w.add((signal, width))
    for signal in outputs:
        width = extract_signal_width(orig_content, signal)
        outputs_w.add((signal, width))

    # Handle module instantiations
    mod_names_all = extract_module_names_all(orig_content)
    mod_instances    = extract_module_instances(code_snippet, mod_names_all)
    port_connections = [extract_ports_connections(mod.strip()) for mod in mod_instances]
    mod_names        = [mod.strip().split()[0] for mod in mod_instances]
    mod_names_set    = set(mod_names)
    for mod_idx in range(len(mod_names)):
        mod_def = find_module_definition(orig_content, mod_names[mod_idx])
        mod_inps, mod_outs = extract_module_io(mod_def)
        # Handle inputs
        for inp in mod_inps:
            connected_sig = port_connections[mod_idx][inp]
            inputs_w.add((connected_sig, extract_signal_width(orig_content, connected_sig)))
        # Handle outputs
        for outp in mod_outs:
            connected_sig = port_connections[mod_idx][outp]
            outputs_w.add((connected_sig, extract_signal_width(orig_content, connected_sig)))

    verilog_mod = create_module_definition(flnm + '_redacted', inputs_w, outputs_w, code_snippet)
    # Extract module definitions
    mod_defs = extract_module_definitions(mod_names_set, orig_content)
    openfpga_inp = verilog_mod + '\n\n' + '\n\n'.join(mod_defs)
    write_to_file(flnm + '_redacted.v', openfpga_inp.strip())
    mod_instantiation_str = create_module_instantiation('fpga', inputs_w, outputs_w)
    redacted_content = substitute_string(orig_content,code_snippet,'//' + mod_instantiation_str)
    write_to_file(flnm +'_instantiated.v',redacted_content.strip())


# Entry point for the script
if __name__ == "__main__":
    main()