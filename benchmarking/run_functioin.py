import json
import os
import subprocess
import shutil

lef_path="Nangate.lef"
lef_paths=["Nangate.lef",
           "OpenROAD-flow-scripts/flow/designs/nangate45/dft48/lef/memMod_dist_0.lef",
           "OpenROAD-flow-scripts/flow/designs/nangate45/dft48/lef/memMod_dist_1.lef",
           "OpenROAD-flow-scripts/flow/designs/nangate45/dft48/lef/memMod_dist_2.lef",
           "OpenROAD-flow-scripts/flow/designs/nangate45/dft48/lef/memMod_dist_3.lef",
           "OpenROAD-flow-scripts/flow/designs/nangate45/or1200/lef/memory4.lef",
           "OpenROAD-flow-scripts/flow/designs/nangate45/or1200/lef/or1200_spram2.lef",
           "OpenROAD-flow-scripts/flow/designs/nangate45/or1200/lef/or1200_spram3.lef",
           "OpenROAD-flow-scripts/flow/designs/nangate45/or1200/lef/or1200_spram4.lef",
           "OpenROAD-flow-scripts/flow/designs/nangate45/or1200/lef/or1200_spram5.lef",
           ]

def replace_slash_in_file_content(file_path):
    if os.path.isfile(file_path):
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            index = content.find('/')
            if index != -1:
                modified_content = content[:index+1] + content[index+1:].replace('/', '_')
               
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(modified_content)
                print(f"File '{file_path}' has been modified.")
            else:
                print(f"No '/' found in the file '{file_path}'.")
        except UnicodeDecodeError:
            print(f"Skipped non-text file: {file_path}")
        except Exception as e:
            print(f"Error processing file {file_path}: {str(e)}")
    else:
        print(f"Path '{file_path}' is not a valid file or not found")

def copy_and_replace(src, dest):

    if os.path.exists(dest):
        return
    if not os.path.exists(src):
        base_dest=os.path.join(dest,"base")
        os.makedirs(base_dest)
        return
    shutil.copytree(src, dest)


def run_macro_openroad(case_name,def_path,evaluate_name=""):

    new_case_name=f"{evaluate_name}_{case_name}"
    copy_and_replace(f"OpenROAD-flow-scripts/flow/logs/nangate45/{case_name}",f"OpenROAD-flow-scripts/flow/logs/nangate45/{new_case_name}")
    copy_and_replace(f"OpenROAD-flow-scripts/flow/results/nangate45/{case_name}",f"OpenROAD-flow-scripts/flow/results/nangate45/{new_case_name}")
    copy_and_replace(f"OpenROAD-flow-scripts/flow/reports/nangate45/{case_name}",f"OpenROAD-flow-scripts/flow/reports/nangate45/{new_case_name}")


    read_lef_commands = "\n".join([f"    read_lef {lef_path}" for lef_path in lef_paths])

    script_content = f"""
    openroad -no_init -exit <<EOF
    {read_lef_commands}
        read_def {def_path}
        write_db OpenROAD-flow-scripts/flow/results/nangate45/{new_case_name}/base/2_4_floorplan_macro.odb
    EOF
"""

    
    script_filename = f"{new_case_name}.tcl"
    with open(script_filename, 'w') as file:
        file.write(script_content)

    
    command=[f"./{script_filename}"]
    env = os.environ.copy()

    env['DESIGN_NICKNAME'] = new_case_name



    os.chmod(script_filename, 0o755)
    print(f"running for {case_name}")
    
    subprocess.run(command, shell=True, env=env)
    os.remove(script_filename)
    

    try:
        command2 = f"cd OpenROAD-flow-scripts/flow/ && make do-macroflow DESIGN_CONFIG=./designs/nangate45/{case_name}/config.mk"
        result = subprocess.run(command2, shell=True, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        
        
        
    except subprocess.CalledProcessError as e:
        print(f"An error occurred while running the command: {e}")
        print("Error output:\n", e.stderr)

def run_global_openroad(case_name,def_path,evaluate_name=""):

    new_case_name=f"{evaluate_name}_{case_name}"
    copy_and_replace(f"OpenROAD-flow-scripts/flow/logs/nangate45/{case_name}",f"OpenROAD-flow-scripts/flow/logs/nangate45/{new_case_name}")
    copy_and_replace(f"OpenROAD-flow-scripts/flow/results/nangate45/{case_name}",f"OpenROAD-flow-scripts/flow/results/nangate45/{new_case_name}")
    copy_and_replace(f"OpenROAD-flow-scripts/flow/reports/nangate45/{case_name}",f"OpenROAD-flow-scripts/flow/reports/nangate45/{new_case_name}")

    
    script_content = f"""
openroad -no_init -exit <<EOF
    read_lef {lef_path}
    read_def {def_path}
    write_db OpenROAD-flow-scripts/flow/results/nangate45/{new_case_name}/base/3_3_place_gp.odb
EOF
    """

    
    script_filename = f"{new_case_name}.tcl"
    with open(script_filename, 'w') as file:
        file.write(script_content)

    
    command=[f"./{script_filename}"]
    env = os.environ.copy()

    env['DESIGN_NICKNAME'] = new_case_name



    os.chmod(script_filename, 0o755)
    print(f"running for {case_name}")
    
    subprocess.run(command, shell=True, env=env)
    os.remove(script_filename)
    

    try:
        command2 = f"cd OpenROAD-flow-scripts/flow/ && make do-globalflow DESIGN_CONFIG=./designs/nangate45/{case_name}/config.mk"
        result = subprocess.run(command2, shell=True, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        
        
        
    except subprocess.CalledProcessError as e:
        print(f"An error occurred while running the command: {e}")
        print("Error output:\n", e.stderr)

def run_mixsize_openroad(case_name,def_path,evaluate_name=""):

    new_case_name=f"{evaluate_name}_{case_name}"
    copy_and_replace(f"OpenROAD-flow-scripts/flow/logs/nangate45/{case_name}",f"OpenROAD-flow-scripts/flow/logs/nangate45/{new_case_name}")
    copy_and_replace(f"OpenROAD-flow-scripts/flow/results/nangate45/{case_name}",f"OpenROAD-flow-scripts/flow/results/nangate45/{new_case_name}")
    copy_and_replace(f"OpenROAD-flow-scripts/flow/reports/nangate45/{case_name}",f"OpenROAD-flow-scripts/flow/reports/nangate45/{new_case_name}")

    
    script_content = f"""
openroad -no_init -exit <<EOF
    read_lef {lef_path}
    read_def {def_path}
    write_db OpenROAD-flow-scripts/flow/results/nangate45/{new_case_name}/base/2_3_place_mixgp.odb
EOF
    """

    
    script_filename = f"{new_case_name}.tcl"
    with open(script_filename, 'w') as file:
        file.write(script_content)

    
    command=[f"./{script_filename}"]
    env = os.environ.copy()

    env['DESIGN_NICKNAME'] = new_case_name



    os.chmod(script_filename, 0o755)
    print(f"running for {case_name}")
    
    subprocess.run(command, shell=True, env=env)
    os.remove(script_filename)
    

    try:
        command2 = f"cd OpenROAD-flow-scripts/flow/ && make do-mixsizeflow DESIGN_CONFIG=./designs/nangate45/{case_name}/config.mk"
        result = subprocess.run(command2, shell=True, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        
        
        
    except subprocess.CalledProcessError as e:
        print(f"An error occurred while running the command: {e}")
        print("Error output:\n", e.stderr)

    
