import json
import os
import subprocess
import shutil
import re
# from datetime import datetime
# from watchdog.observers import Observer
# from watchdog.events import FileSystemEventHandler



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
                #print(f"File '{file_path}' has been modified.")
            else:
                pass
                #print(f"No '/' found in the file '{file_path}'.")
        except UnicodeDecodeError:
            pass
            #print(f"Skipped non-text file: {file_path}")
        except Exception as e:
            pass
            #print(f"Error processing file {file_path}: {str(e)}")
    else:
        pass
        #print(f"Path '{file_path}' is not a valid file or not found")

def rm_blockages_process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()

    blockages_pattern = r"BLOCKAGES \d+ ;.*?END BLOCKAGES"

    processed_content = re.sub(blockages_pattern, '', content, flags=re.DOTALL)

    with open(file_path, 'w', encoding='utf-8') as file:
        file.write(processed_content)





def parse_issue_variables(data, target="ISSUE_VARIABLES"):
    """
    Extract variables starting with target and stopping at '#' or other line beginnings, and parse them into a dictionary.
    """
    # Extract target block content
    pattern = rf"{target}\s*:=\s*(.*?)\n#"
    match = re.search(pattern, data, re.DOTALL)
    if not match:
        raise ValueError(f"Target variable block not found: {target}")
    
    block_content = match.group(1)
    # print(block_content)

    # Parse each line for variables and values
    variables = {}
    for line in block_content.splitlines():
        line = line.strip()
        if not line:  # Skip empty lines
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip()
        if " " in value:  # If the value contains spaces, save it as a list
            variables[key] = value.split()
        else:  # Save single value variables directly
            variables[key] = value
    
    return variables



def load_makefile_env(design_config,flow_variant=""):
    # Use make command to export environment variables
    result = subprocess.run(
        ["make",f"DESIGN_CONFIG={design_config}",f"FLOW_VARIANT={flow_variant}", "-p", "noop"], 
        stdout=subprocess.PIPE, 
        text=True,
        cwd="flow/"
    )
    
    # Parse the output of the make command
    data = result.stdout
    try:
        env_vars = parse_issue_variables(data)
        return env_vars
        # print("Loaded environment variables:", env_vars)  # Use English for output
    except ValueError as e:
        print(f"Error: {e}")
        return None

def def2db(config_setting,flow_variant,def_path,db_path):
    os.makedirs("def_tmp",exist_ok=True)
    tmp_def_path=f"def_tmp/{os.path.basename(def_path)}"
    tmp_def_path_abs=os.path.abspath(tmp_def_path)
    os.system(f"cp {def_path} {tmp_def_path_abs}")
    replace_slash_in_file_content(tmp_def_path_abs)
    rm_blockages_process_file(tmp_def_path_abs)
    subprocess.run([f"make DESIGN_CONFIG={config_setting} FLOW_VARIANT={flow_variant} TARGET_DEF_PATH={tmp_def_path_abs} TARGET_DB_PATH={db_path} def2db"],shell=True)
    os.system(f"rm {tmp_def_path_abs}")

def copy2synth(config_setting,evaluate_name,netlist):
    config_setting_abs=os.path.abspath(config_setting)
    original_dir = os.getcwd()
    # os.chdir("flow")

    subprocess.run([f"make DESIGN_CONFIG={config_setting_abs} FLOW_VARIANT={evaluate_name} init_flow"],shell=True,cwd="flow")
    # os.chdir(original_dir)
    env_vars=load_makefile_env(config_setting_abs,evaluate_name)
    result_dir=env_vars.get("RESULTS_DIR",None)
    result_dir=os.path.join(original_dir,"flow",result_dir)
    
    os.system(f"cp {netlist} {result_dir}/1_synth.v")

def run_or_flow(config_setting,evaluate_name,def_path,mode):
    # print(mode)
    if mode == 1:
        flow_cmd="evaluate_MacroPlace"
        db_path="2_3_floorplan_macro.odb"
        
    elif mode ==2:
        flow_cmd="evaluate_GlobalPlace"
        db_path="3_3_place_gp.odb"
        
    elif mode ==3:
        flow_cmd="evaluate_Mixed-SizePlace"
        db_path="2_3_place_mixgp.odb"
    elif mode ==4:
        flow_cmd="evaluate_Synth"
        db_path="1_synth.v"
    elif mode =="0":
        flow_cmd=""
    # print(flow_cmd)

    config_setting_abs=os.path.abspath(config_setting)
    
    if def_path:
        def_path_abs=os.path.abspath(def_path)
    if mode ==4:
        copy2synth(config_setting_abs,evaluate_name,def_path_abs)

    original_dir = os.getcwd()  
    os.chdir("flow")
    if flow_cmd and not mode ==4:
        def2db(config_setting_abs,evaluate_name,def_path_abs,db_path)
    subprocess.run([f"make DESIGN_CONFIG={config_setting_abs} FLOW_VARIANT={evaluate_name} {flow_cmd}"],shell=True)
    os.chdir(original_dir)  
    
def getMacroMetrics(config_setting,evaluate_name,def_path,mode):


    config_setting_abs=os.path.abspath(config_setting)
    

    original_dir = os.getcwd()  
    os.chdir("flow")
    subprocess.run([f"make DESIGN_CONFIG={config_setting_abs} FLOW_VARIANT={evaluate_name} getMacroMetrics"],shell=True)
    os.chdir(original_dir)  
