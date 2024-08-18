import json
import os
import subprocess
import shutil
import re
from datetime import datetime
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

lef_path="Nangate.lef"
lef_paths=["Nangate.lef",
           ]

stage_dict={
    "dp":"Detailed Placement",
    "tapcell":"Tapcell and Welltie insertion",
    "pdn":"PDN generation",
    "resized":"Resizing & Buffering",
    "cts":"CTS",
    "fillcell":"Filler cell insertion",
    "grt":"Global Rotue",
    "route":"Detailed Route",
    "report":"report"    
}

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
    run_openroad(case_name,def_path,3,evaluate_name)
    
def run_openroad(case_name,def_path,mode,evaluate_name=""):
    create_result_dir(case_name)
    new_case_name=f"{evaluate_name}_{case_name}"
    copy_and_replace(f"OpenROAD-flow-scripts/flow/logs/nangate45/{case_name}",f"OpenROAD-flow-scripts/flow/logs/nangate45/{new_case_name}")
    copy_and_replace(f"OpenROAD-flow-scripts/flow/results/nangate45/{case_name}",f"OpenROAD-flow-scripts/flow/results/nangate45/{new_case_name}")
    copy_and_replace(f"OpenROAD-flow-scripts/flow/reports/nangate45/{case_name}",f"OpenROAD-flow-scripts/flow/reports/nangate45/{new_case_name}")





    if mode == 1:
        flow_cmd="do-macroflow"
        db_file="2_4_floorplan_macro.odb"
        
    elif mode ==2:
        flow_cmd="do-globalflow"
        db_file="3_3_place_gp.odb"
        
    elif mode ==3:
        flow_cmd="do-mixsizedflow"
        db_file="2_3_place_mixgp.odb"
        

    extra_lef_path= get_all_files_in_directory(f"OpenROAD-flow-scripts/flow/designs/nangate45/{case_name}/lef")
    lef_paths_new=lef_paths+extra_lef_path
    read_lef_commands = "\n".join([f"    read_lef {lef_path}" for lef_path in lef_paths_new])

    script_content = f"""
    openroad -no_init -exit <<EOF
    {read_lef_commands}
        read_def {def_path}
        write_db OpenROAD-flow-scripts/flow/results/nangate45/{new_case_name}/base/{db_file}
    EOF
"""

    
    script_filename = f"{new_case_name}.tcl"
    with open(script_filename, 'w') as file:
        file.write(script_content)

    
    command=[f"./{script_filename}"]
    env = os.environ.copy()

    env['DESIGN_NICKNAME'] = new_case_name

    

    os.chmod(script_filename, 0o755)
    
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"----- [{timestamp}] Starting benchmarking flow for case: '{case_name}' -----")

    #print(f"--------------running for {case_name}----------------------")
    
    print("Converting to db file")
    subprocess.run(command, shell=True, env=env)
    os.remove(script_filename)
    print("Conversion completed")

    directory_to_monitor = f"OpenROAD-flow-scripts/flow/logs/nangate45/{new_case_name}/base"
    
    observer = monitor_directory(directory_to_monitor)
    

    try:
        command2 = f"cd OpenROAD-flow-scripts/flow/ && make {flow_cmd} DESIGN_CONFIG=./designs/nangate45/{case_name}/config.mk"

        error_pattern = re.compile(r'make\[\d+\]: \*\*\* \[Makefile:\d+: (.*?)\] Error \d+')


        process = subprocess.Popen(
            command2, shell=True, env=env, 
            stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True
        )
        
        while process.poll() is None:
            line = process.stderr.readline()
            if line:
                match = error_pattern.search(line)
                if match:
                    error_detail = match.group(1)
                    true_error = find_error(error_detail)
                    if true_error in stage_dict:
                        error_name=stage_dict[true_error]
                        print(f"Error: {error_name}")
                    else:
                        print(f"Error: {true_error}")
                    break

        
        process.wait()

        
                
        
        
        
    except subprocess.CalledProcessError as e:
        print(f"An error occurred while running the command: {e}")
        print("Error output:\n", e.stderr)
    finally:
        observer.stop()
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"----- [{timestamp}] ended flow for case: '{case_name}' -----")


    observer.join()    


def find_error(error_str):
    

    last_underscore_index = error_str.rfind('_')

    if last_underscore_index != -1:
        result_str = error_str[last_underscore_index + 1:]
    else:
        result_str = error_str

    return result_str


def get_all_filenames(directory):
    filenames = os.listdir(directory)
    return [f for f in filenames if os.path.isfile(os.path.join(directory, f))]

def get_all_files_in_directory(directory_path):
    return [os.path.abspath(os.path.join(directory_path, file)) for file in os.listdir(directory_path) if os.path.isfile(os.path.join(directory_path, file))]

def extract_string(s):
    last_underscore = s.rfind("_")
    
    next_dot = s.find(".", last_underscore)
    
    if last_underscore != -1 and next_dot != -1:
        return s[last_underscore + 1:next_dot]
    else:
        return None 



class FileChangeHandler(FileSystemEventHandler):

    def on_created(self, event):
        path=os.path.basename(event.src_path)
        stage_in=extract_string(path)

        if stage_in in stage_dict:
            stage=stage_dict[stage_in]
        else:
            stage=stage_in

        if "tmp" in path:
            print(f"start: {stage}")
        else:
            print(f"finish: {stage}")

        


def monitor_directory(directory_path):
    event_handler = FileChangeHandler()
    observer = Observer()
    observer.schedule(event_handler, path=directory_path, recursive=True)
    observer.start()
    return observer


# def create_result_dir(case_name):
#     os.mkdir(f"OpenROAD-flow-scripts/flow/logs/nangate45/{case_name}/base")
#     shutil.copy
#     return

def create_result_dir(case_name):
    target_dir = f"OpenROAD-flow-scripts/flow/results/nangate45/{case_name}/base"
    os.makedirs(target_dir, exist_ok=True)
    
    source_dir = f"OpenROAD-flow-scripts/flow/designs/nangate45/{case_name}"
    sdc_file = None
    for file_name in os.listdir(source_dir):
        if file_name.endswith(".sdc"):
            sdc_file = os.path.join(source_dir, file_name)
            break  
    
    if sdc_file:
        shutil.copy(sdc_file, os.path.join(target_dir, "1_synth.sdc"))
        shutil.copy(sdc_file, os.path.join(target_dir, "2_floorplan.sdc"))
    else:
        print("Error: No .sdc file found in the source directory.")
    
    return