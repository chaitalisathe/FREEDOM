# Import necessary libraries/modules
import os
import sys
import re

# Define functions
def get_verilog_files(folder):
    """
    Returns a list of relative paths for all Verilog files in the given folder.
    
    Parameters:
        folder (str): The path to the directory to search.

    Returns:
        list of str: A list containing the relative paths of all Verilog files.
    """
    verilog_files = []
    
    # Walk through the directory tree.
    for root, dirs, files in os.walk(folder):
        for file in files:
            # Check if the file is a Verilog file. You can add more extensions if needed.
            if file.endswith('.v'):
                # Get the full path of the file.
                full_path = os.path.join(root, file)
                # Convert it to a relative path.
                rel_path = os.path.relpath(full_path, './')
                verilog_files.append(rel_path.replace('\\','/'))
                
    return verilog_files


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
        filename (str): The name/path of the file to write to.
        content (str): The content to write.

    Returns:
        None
    """
    with open(filename, "w") as file:
        file.write(content)


def replace_whole_word(text, old_word, new_word):
    # Use word boundaries (\b) to match only whole words
    pattern = rf"\b{re.escape(old_word)}\b"
    return re.sub(pattern, new_word, text)

def replace_word_in_file(file_path, old_word, new_word):
    old_c = read_file(file_path)
    new_c = replace_whole_word(old_c,old_word, new_word)
    write_to_file(file_path,new_c)

def main():
    # Read command line args
    bench_name = sys.argv[1]

    # Generate qsf file
    routing_path = 'hardware/SRC/routing/'
    sub_mod_path = 'hardware/SRC/sub_module/'
    lb_path      = 'hardware/SRC/lb/'
    routing_files = get_verilog_files(routing_path)
    sub_mod_files = [f for f in get_verilog_files(sub_mod_path) if 'user_defined_templates.v' not in f]
    lb_files      = get_verilog_files(lb_path)
    files = routing_files + sub_mod_files + lb_files
    project_lines = ['set_global_assignment -name VERILOG_FILE ' + ver_file for ver_file in files]
    append_str = '\n'.join(project_lines)
    template_str = read_file('./asic_fpga_benchmark_top.qsf')
    template_str = template_str.format(benchmark_name=bench_name)
    write_to_file('asic_fpga_{0}_top.qsf'.format(bench_name), template_str + '\n\n' + append_str)

    # Generate qpf file
    qpf_template = read_file('./asic_fpga_benchmark_top.qpf')
    qpf_gen = qpf_template.format(benchmark_name=bench_name)
    write_to_file('asic_fpga_{0}_top.qpf'.format(bench_name), qpf_gen)

    # Modify verilog files
    replace_word_in_file('./hardware/SRC/sub_module/memories.v', 'DFF', 'DFF_user')
    replace_word_in_file('./hardware/SRC/sub_module/luts.v', 'OR2', 'OR2_user')
    replace_word_in_file('./hardware/SRC/sub_module/inv_buf_passgate.v', 'OR2', 'OR2_user')

    # Generate SDC file
    sdc_str = read_file('asic_fpga_benchmark_top.sdc')
    write_to_file('asic_fpga_{0}_top.sdc'.format(bench_name), sdc_str)

if __name__ == "__main__":
    main()