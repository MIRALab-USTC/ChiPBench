import json
import sys
import os
import shutil
import concurrent.futures
import argparse
import pandas as pd
import copy

from getMetric import getMetrics,get_metrics_single
from run_functioin import run_or_flow,load_makefile_env,getMacroMetrics





def mode_to_int(mode):
    if mode == "macro":
        return 1
    elif mode == "global":
        return 2
    elif mode == "mixedsize":
        return 3
    elif mode == "synth":
        return 4
    else:
        return mode

def dict_to_table(data):
    data_tmp = copy.deepcopy(data)  
    for key, value in data_tmp.items():
        value.pop("unit", None)  

    pd.set_option('display.float_format', '{:.2f}'.format)
    df = pd.DataFrame.from_dict(data_tmp, orient='index')
    pd.set_option('display.max_columns', None)  
    pd.set_option('display.max_rows', None)     
    print(df)



def benchmarking_single_in(config_setting,def_path,evaluate_name,mode,baseline_data_file=""):
    mode=mode_to_int(mode)
    if def_path:
        run_or_flow(config_setting,evaluate_name,def_path,mode)

    else:
        getMacroMetrics(config_setting,evaluate_name,def_path,mode)

    config_setting_abs=os.path.abspath(config_setting)
    env_vars=load_makefile_env(config_setting_abs,evaluate_name)
    original_dir = os.getcwd()
    log_dir=env_vars.get("LOG_DIR",None)
    result_dir=env_vars.get("RESULTS_DIR",None)
    report_dir=env_vars.get("REPORTS_DIR",None)
    design_name=env_vars.get("DESIGN_NICKNAME",None)
    log_dir=os.path.join(original_dir,"flow",log_dir)
    result_dir=os.path.join(original_dir,"flow",result_dir)
    report_dir=os.path.join(original_dir,"flow",report_dir)

    metrics_dict=get_metrics_single(log_dir)
    # print(dict_to_markdown_table(metrics_dict.pop("unit")))
    return design_name,metrics_dict,log_dir,result_dir,report_dir


def benchmarking_single(config_setting,def_path,evaluate_name,mode,baseline_data_file=""):
    design_name,metrics_dict,log_dir,result_dir,report_dir=benchmarking_single_in(config_setting,def_path,evaluate_name,mode,baseline_data_file)
    os.makedirs(f"benchmarking_result/{evaluate_name}",exist_ok=True)
    final_metrics_dict={}
    final_metrics_dict[design_name]=metrics_dict

    dict_to_table(final_metrics_dict)
    if evaluate_name=="openroad":
        with open(f"benchmarking_result/{evaluate_name}/metrics.json","r") as f:
            openroad_metrics=json.load(f)
        for design_name,metrics in final_metrics_dict.items():
            openroad_metrics[design_name]=metrics
        with open(f"benchmarking_result/{evaluate_name}/metrics.json","w") as f:
            json.dump(openroad_metrics,f,indent=4)
    else:

        metrics_file_path = f"benchmarking_result/{evaluate_name}/metrics.json"
        if not os.path.exists(metrics_file_path):
            with open(metrics_file_path, "w") as f:
                json.dump({}, f)

        with open(metrics_file_path, "r") as f:
            openroad_metrics = json.load(f)
        for design_name, metrics in final_metrics_dict.items():
            openroad_metrics[design_name] = metrics
        with open(metrics_file_path, "w") as f:
            json.dump(openroad_metrics, f, indent=4)
        # with open(f"benchmarking_result/{evaluate_name}/metrics.json","w") as f:
        #     json.dump(final_metrics_dict,f,indent=4)
    return design_name,metrics_dict,log_dir,result_dir,report_dir

def benchmarking_multi(config):

    parallel=config["parallel"]
    evaluate_name=config["evaluate_name"]
    mode=config["mode"]
    case_list:list=config["case_list"]

    multi_metrics_dict={}
    log_dir_dict={}
    result_dir_dict={}
    report_dir_dict={}


    if not parallel:

        for case in case_list:
            config_setting=case["config_setting"]
            def_path=case["def_path"]
            design_name,metrics_dict,log_dir,result_dir,report_dir=benchmarking_single_in(config_setting,def_path,evaluate_name,mode)
            multi_metrics_dict[design_name]=metrics_dict
            log_dir_dict[design_name]=log_dir
            result_dir_dict[design_name]=result_dir
            report_dir_dict[design_name]=report_dir

    else:

        with concurrent.futures.ThreadPoolExecutor(max_workers=parallel) as executor:
            futures = {executor.submit(benchmarking_single_in, case_config["config_setting"], case_config["def_path"], evaluate_name, mode): case_config["evaluate_name"] for case_config in case_list}
            for future in concurrent.futures.as_completed(futures):
                design_name,metrics_dict,log_dir,result_dir,report_dir = future.result()
                multi_metrics_dict[design_name]=metrics_dict
                log_dir_dict[design_name]=log_dir
                result_dir_dict[design_name]=result_dir
                report_dir_dict[design_name]=report_dir
    

    dict_to_table(multi_metrics_dict)





    return multi_metrics_dict,log_dir_dict,result_dir_dict,report_dir_dict





def benchmarking(args):
    if args.config_json is not None:
        with open(args.config_json,"r") as f:
            config=json.load(f)
        if "case_list" in config:
            benchmarking_multi(config)
        else: # single case
            benchmarking_single(config["config_setting"],config["def_path"],config["evaluate_name"],config["mode"])
    elif  args.mode is not None:
        print(args.config_setting)
        benchmarking_single(args.config_setting,args.def_path,args.evaluate_name,args.mode,args.baseline_data_file)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Benchmarking script')
    parser.add_argument('--config_json', required=False, help='Path to the configuration json file')
    parser.add_argument('--config_setting', required=False, help='Path to the config.mk file of a specific case')
    parser.add_argument('--def_path', required=False, help='Path to the def file of a specific case')
    parser.add_argument('--evaluate_name', required=False, help='Evaluate name of the benchmarking')
    parser.add_argument('--mode', required=False, help='Mode of the benchmarking')
    parser.add_argument('--baseline_data_file', required=False, help='Path to the baseline data file')
    args = parser.parse_args()

    benchmarking(args)






