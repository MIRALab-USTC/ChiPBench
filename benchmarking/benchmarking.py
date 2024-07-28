import json
import sys
import os
import shutil
import concurrent.futures
import argparse
import pandas as pd
import copy

from getMetric import getMetrics,get_metrics_single
from run_functioin import run_or_flow,load_makefile_env


# openroad_metric_path="benchmarking_result/openroad/metrics.json"

# def normalize_metric(metrics_dict:dict):
#     normalized_metric={}

#     with open(openroad_metric_path,"r") as f:
#         openroad_metrics=json.load(f)

#     for case_name,metirc in metrics_dict.items():
#         if case_name in openroad_metrics:
#             normalized_metric[case_name]={}
#             for metric_name,value in metirc.items():
#                 if value is None:
#                     normalize_value=None
#                 else:
#                     normalize_value= value/openroad_metrics[case_name][metric_name]
#                 normalized_metric[case_name][metric_name]=normalize_value


#     case_num=len(normalized_metric)
#     average_metrics = {}
#     for case,metirc in normalized_metric.items():
        
#         for metirc_name,value in metirc.items():
#             if metirc_name not in average_metrics:
#                 average_metrics[metirc_name]=0
#             if value is None or average_metrics[metirc_name] is None:
#                 average_metrics[metirc_name]=None
#             else:
#                 average_metrics[metirc_name]+=value

#     for key in average_metrics.keys():
#         if average_metrics[key] is None:
#             average_metrics[key] =None
#         else:
#             average_metrics[key]/=case_num

    






#     return normalized_metric,average_metrics



# def move2final(evaluate_name, log_paths, result_paths, report_paths):

    
#     base_path = "benchmarking_result"

#     evaluate_dir = os.path.join(base_path, evaluate_name)
#     os.makedirs(evaluate_dir, exist_ok=True)
    
    
#     logs_dir = os.path.join(evaluate_dir, "logs")
#     results_dir = os.path.join(evaluate_dir, "results")
#     reports_dir = os.path.join(evaluate_dir, "reports")
    
#     os.makedirs(logs_dir, exist_ok=True)
#     os.makedirs(results_dir, exist_ok=True)
#     os.makedirs(reports_dir, exist_ok=True)
    
    
#     def copy_directory(src, dest):
#         if os.path.exists(dest):
#             shutil.rmtree(dest) 
#         shutil.copytree(src, dest)
#         shutil.rmtree(src)
    
    
#     for path in log_paths:
#         dest_path = os.path.join(logs_dir, os.path.basename(path[1]))
#         copy_directory(path[0], dest_path)
        
#     for path in result_paths:
#         dest_path = os.path.join(results_dir, os.path.basename(path[1]))
#         copy_directory(path[0], dest_path)
        
#     for path in report_paths:
#         dest_path = os.path.join(reports_dir, os.path.basename(path[1]))
#         copy_directory(path[0], dest_path)


# def macro_flow(case_name,def_path,evaluate_name=""):
#     new_case_name=f"{evaluate_name}_{case_name}"


#     log_path=[f"OpenROAD-flow-scripts/flow/logs/nangate45/{new_case_name}",f"OpenROAD-flow-scripts/flow/logs/nangate45/{case_name}"]
#     result_path=[f"OpenROAD-flow-scripts/flow/results/nangate45/{new_case_name}",f"OpenROAD-flow-scripts/flow/results/nangate45/{case_name}"]
#     report_path=[f"OpenROAD-flow-scripts/flow/reports/nangate45/{new_case_name}",f"OpenROAD-flow-scripts/flow/reports/nangate45/{case_name}"]

#     def_tmp_path=os.path.join("OpenROAD-flow-scripts/def_tmp",f"{new_case_name}.def")

#     shutil.copy(def_path, def_tmp_path)
#     #return log_path,result_path,report_path
#     replace_slash_in_file_content(def_tmp_path)
#     run_macro_openroad(case_name,def_tmp_path,evaluate_name)
    
#     return log_path,result_path,report_path


# def global_flow(case_name,def_path,evaluate_name=""):
#     new_case_name=f"{evaluate_name}_{case_name}"


#     log_path=[f"OpenROAD-flow-scripts/flow/logs/nangate45/{new_case_name}",f"OpenROAD-flow-scripts/flow/logs/nangate45/{case_name}"]
#     result_path=[f"OpenROAD-flow-scripts/flow/results/nangate45/{new_case_name}",f"OpenROAD-flow-scripts/flow/results/nangate45/{case_name}"]
#     report_path=[f"OpenROAD-flow-scripts/flow/reports/nangate45/{new_case_name}",f"OpenROAD-flow-scripts/flow/reports/nangate45/{case_name}"]

#     def_tmp_path=os.path.join("OpenROAD-flow-scripts/def_tmp",f"{new_case_name}.def")

#     shutil.copy(def_path, def_tmp_path)
#     #return log_path,result_path,report_path
#     replace_slash_in_file_content(def_tmp_path)
#     run_global_openroad(case_name,def_tmp_path,evaluate_name)
    
#     return log_path,result_path,report_path

# def mixsize_flow(case_name,def_path,evaluate_name=""):
#     new_case_name=f"{evaluate_name}_{case_name}"


#     log_path=[f"OpenROAD-flow-scripts/flow/logs/nangate45/{new_case_name}",f"OpenROAD-flow-scripts/flow/logs/nangate45/{case_name}"]
#     result_path=[f"OpenROAD-flow-scripts/flow/results/nangate45/{new_case_name}",f"OpenROAD-flow-scripts/flow/results/nangate45/{case_name}"]
#     report_path=[f"OpenROAD-flow-scripts/flow/reports/nangate45/{new_case_name}",f"OpenROAD-flow-scripts/flow/reports/nangate45/{case_name}"]

#     def_tmp_path=os.path.join("OpenROAD-flow-scripts/def_tmp",f"{new_case_name}.def")

#     shutil.copy(def_path, def_tmp_path)
#     #return log_path,result_path,report_path
#     replace_slash_in_file_content(def_tmp_path)
#     run_mixsize_openroad(case_name,def_tmp_path,evaluate_name)
    
#     return log_path,result_path,report_path



# def macro_mode(config:dict):

#     parallel=config["parallel"]
#     evaluate_name=config["evaluate_name"]

#     case:dict=config["case"]
#     log_paths=[]
#     result_paths=[]
#     report_paths=[]

#     if not parallel:

#         for name,def_path in case.items():
#             log_path,result_path,report_path=macro_flow(name,def_path,evaluate_name)
            
#             log_paths.append(log_path)
#             result_paths.append(result_path)
#             report_paths.append(report_path)
#     else:

#         with concurrent.futures.ThreadPoolExecutor(max_workers=parallel) as executor:
#             futures = {executor.submit(macro_flow, name, def_path, evaluate_name): name for name, def_path in case.items()}
#             for future in concurrent.futures.as_completed(futures):
#                 log_path, result_path, report_path = future.result()
#                 log_paths.append(log_path)
#                 result_paths.append(result_path)
#                 report_paths.append(report_path)


#     move2final(evaluate_name,log_paths,result_paths,report_paths)

#     final_result_dir=os.path.join("benchmarking_result",evaluate_name)

#     final_logs_dir=os.path.join(final_result_dir,"logs")


#     metrics_dict=getMetrics(final_logs_dir)

    
#     normalized_metrics,average_metrics=normalize_metric(metrics_dict)

#     metric_path=os.path.join(final_result_dir,"metrics.json")
#     normalized_path=os.path.join(final_result_dir,"normalized_metrics.json")
#     average_path=os.path.join(final_result_dir,"average_result.json")

#     with open(metric_path,"w") as f:
#         json.dump(metrics_dict,f,indent=4)

    

#     with open(normalized_path,"w") as f:
#         json.dump(normalized_metrics,f,indent=4)

#     with open(average_path,"w") as f:
#         json.dump(average_metrics,f,indent=4)

#     return 0

# def global_mode(config:dict):

#     parallel=config["parallel"]
#     evaluate_name=config["evaluate_name"]

#     case:dict=config["case"]
#     log_paths=[]
#     result_paths=[]
#     report_paths=[]

#     if not parallel:

#         for name,def_path in case.items():
#             log_path,result_path,report_path=global_flow(name,def_path,evaluate_name)
            
#             log_paths.append(log_path)
#             result_paths.append(result_path)
#             report_paths.append(report_path)
#     else:

#         with concurrent.futures.ThreadPoolExecutor(max_workers=parallel) as executor:
#             futures = {executor.submit(global_flow, name, def_path, evaluate_name): name for name, def_path in case.items()}
#             for future in concurrent.futures.as_completed(futures):
#                 log_path, result_path, report_path = future.result()
#                 log_paths.append(log_path)
#                 result_paths.append(result_path)
#                 report_paths.append(report_path)


#     move2final(evaluate_name,log_paths,result_paths,report_paths)

#     final_result_dir=os.path.join("benchmarking_result",evaluate_name)


#     final_logs_dir=os.path.join(final_result_dir,"logs")


#     metrics_dict=getMetrics(final_logs_dir)
    



    
#     normalized_metrics,average_metrics=normalize_metric(metrics_dict)

#     metric_path=os.path.join(final_result_dir,"metrics.json")
#     normalized_path=os.path.join(final_result_dir,"normalized_metrics.json")
#     average_path=os.path.join(final_result_dir,"average_result.json")

#     with open(metric_path,"w") as f:
#         json.dump(metrics_dict,f,indent=4)

#     with open(normalized_path,"w") as f:
#         json.dump(normalized_metrics,f,indent=4)

#     with open(average_path,"w") as f:
#         json.dump(average_metrics,f,indent=4)


#     return 0



# def mixsize_mode(config:dict):
#     parallel=config["parallel"]
#     evaluate_name=config["evaluate_name"]

#     case:dict=config["case"]
#     log_paths=[]
#     result_paths=[]
#     report_paths=[]

#     if not parallel:

#         for name,def_path in case.items():
#             log_path,result_path,report_path=mixsize_flow(name,def_path,evaluate_name)
            
#             log_paths.append(log_path)
#             result_paths.append(result_path)
#             report_paths.append(report_path)
#     else:

#         with concurrent.futures.ThreadPoolExecutor(max_workers=parallel) as executor:
#             futures = {executor.submit(mixsize_flow, name, def_path, evaluate_name): name for name, def_path in case.items()}
#             for future in concurrent.futures.as_completed(futures):
#                 log_path, result_path, report_path = future.result()
#                 log_paths.append(log_path)
#                 result_paths.append(result_path)
#                 report_paths.append(report_path)


#     move2final(evaluate_name,log_paths,result_paths,report_paths)

#     final_result_dir=os.path.join("benchmarking_result",evaluate_name)


#     final_logs_dir=os.path.join(final_result_dir,"logs")


#     metrics_dict=getMetrics(final_logs_dir)
    
#     normalized_metrics,average_metrics=normalize_metric(metrics_dict)

#     metric_path=os.path.join(final_result_dir,"metrics.json")
#     normalized_path=os.path.join(final_result_dir,"normalized_metrics.json")
#     average_path=os.path.join(final_result_dir,"average_result.json")

#     with open(metric_path,"w") as f:
#         json.dump(metrics_dict,f,indent=4)

#     with open(normalized_path,"w") as f:
#         json.dump(normalized_metrics,f,indent=4)

#     with open(average_path,"w") as f:
#         json.dump(average_metrics,f,indent=4)


    
#     return 0



def mode_to_int(mode):
    if mode == "macro":
        return 1
    elif mode == "global":
        return 2
    elif mode == "mixedsize":
        return 3
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
            benchmarking_single(config["config_setting"],config["def_path"],config["evaluate_name"],config["mode"],config["baseline_data_file"])
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






