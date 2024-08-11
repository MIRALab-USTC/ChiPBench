import json
import sys
import os
import shutil
import concurrent.futures

from getMetric import getMetrics
from run_functioin import replace_slash_in_file_content,run_macro_openroad,run_global_openroad,run_mixsize_openroad


openroad_metric_path="benchmarking_result/openroad/metrics.json"

def normalize_metric(metrics_dict:dict):
    normalized_metric={}

    with open(openroad_metric_path,"r") as f:
        openroad_metrics=json.load(f)

    for case_name,metirc in metrics_dict.items():
        if case_name in openroad_metrics:
            normalized_metric[case_name]={}
            for metric_name,value in metirc.items():
                if value is None:
                    normalize_value=None
                else:
                    normalize_value= value/openroad_metrics[case_name][metric_name]
                normalized_metric[case_name][metric_name]=normalize_value


    case_num=len(normalized_metric)
    average_metrics = {}
    for case,metirc in normalized_metric.items():
        
        for metirc_name,value in metirc.items():
            if metirc_name not in average_metrics:
                average_metrics[metirc_name]=0
            if value is None or average_metrics[metirc_name] is None:
                average_metrics[metirc_name]=None
            else:
                average_metrics[metirc_name]+=value

    for key in average_metrics.keys():
        if average_metrics[key] is None:
            average_metrics[key] =None
        else:
            average_metrics[key]/=case_num

    






    return normalized_metric,average_metrics



def move2final(evaluate_name, log_paths, result_paths, report_paths):

    
    base_path = "benchmarking_result"

    evaluate_dir = os.path.join(base_path, evaluate_name)
    os.makedirs(evaluate_dir, exist_ok=True)
    
    
    logs_dir = os.path.join(evaluate_dir, "logs")
    results_dir = os.path.join(evaluate_dir, "results")
    reports_dir = os.path.join(evaluate_dir, "reports")
    
    os.makedirs(logs_dir, exist_ok=True)
    os.makedirs(results_dir, exist_ok=True)
    os.makedirs(reports_dir, exist_ok=True)
    
    
    def copy_directory(src, dest):
        if os.path.exists(dest):
            shutil.rmtree(dest) 
        shutil.copytree(src, dest)
        shutil.rmtree(src)
    
    
    for path in log_paths:
        dest_path = os.path.join(logs_dir, os.path.basename(path[1]))
        copy_directory(path[0], dest_path)
        
    for path in result_paths:
        dest_path = os.path.join(results_dir, os.path.basename(path[1]))
        copy_directory(path[0], dest_path)
        
    for path in report_paths:
        dest_path = os.path.join(reports_dir, os.path.basename(path[1]))
        copy_directory(path[0], dest_path)


def macro_flow(case_name,def_path,evaluate_name=""):
    new_case_name=f"{evaluate_name}_{case_name}"


    log_path=[f"OpenROAD-flow-scripts/flow/logs/nangate45/{new_case_name}",f"OpenROAD-flow-scripts/flow/logs/nangate45/{case_name}"]
    result_path=[f"OpenROAD-flow-scripts/flow/results/nangate45/{new_case_name}",f"OpenROAD-flow-scripts/flow/results/nangate45/{case_name}"]
    report_path=[f"OpenROAD-flow-scripts/flow/reports/nangate45/{new_case_name}",f"OpenROAD-flow-scripts/flow/reports/nangate45/{case_name}"]

    def_tmp_path=os.path.join("OpenROAD-flow-scripts/def_tmp",f"{new_case_name}.def")

    shutil.copy(def_path, def_tmp_path)
    #return log_path,result_path,report_path
    replace_slash_in_file_content(def_tmp_path)
    run_macro_openroad(case_name,def_tmp_path,evaluate_name)
    
    return log_path,result_path,report_path


def global_flow(case_name,def_path,evaluate_name=""):
    new_case_name=f"{evaluate_name}_{case_name}"


    log_path=[f"OpenROAD-flow-scripts/flow/logs/nangate45/{new_case_name}",f"OpenROAD-flow-scripts/flow/logs/nangate45/{case_name}"]
    result_path=[f"OpenROAD-flow-scripts/flow/results/nangate45/{new_case_name}",f"OpenROAD-flow-scripts/flow/results/nangate45/{case_name}"]
    report_path=[f"OpenROAD-flow-scripts/flow/reports/nangate45/{new_case_name}",f"OpenROAD-flow-scripts/flow/reports/nangate45/{case_name}"]

    def_tmp_path=os.path.join("OpenROAD-flow-scripts/def_tmp",f"{new_case_name}.def")

    shutil.copy(def_path, def_tmp_path)
    #return log_path,result_path,report_path
    replace_slash_in_file_content(def_tmp_path)
    run_global_openroad(case_name,def_tmp_path,evaluate_name)
    
    return log_path,result_path,report_path

def mixsize_flow(case_name,def_path,evaluate_name=""):
    new_case_name=f"{evaluate_name}_{case_name}"


    log_path=[f"OpenROAD-flow-scripts/flow/logs/nangate45/{new_case_name}",f"OpenROAD-flow-scripts/flow/logs/nangate45/{case_name}"]
    result_path=[f"OpenROAD-flow-scripts/flow/results/nangate45/{new_case_name}",f"OpenROAD-flow-scripts/flow/results/nangate45/{case_name}"]
    report_path=[f"OpenROAD-flow-scripts/flow/reports/nangate45/{new_case_name}",f"OpenROAD-flow-scripts/flow/reports/nangate45/{case_name}"]

    def_tmp_path=os.path.join("OpenROAD-flow-scripts/def_tmp",f"{new_case_name}.def")

    shutil.copy(def_path, def_tmp_path)
    #return log_path,result_path,report_path
    replace_slash_in_file_content(def_tmp_path)
    run_mixsize_openroad(case_name,def_tmp_path,evaluate_name)
    
    return log_path,result_path,report_path



def macro_mode(config:dict):

    parallel=config["parallel"]
    evaluate_name=config["evaluate_name"]

    case:dict=config["case"]
    log_paths=[]
    result_paths=[]
    report_paths=[]

    if not parallel:

        for name,def_path in case.items():
            log_path,result_path,report_path=macro_flow(name,def_path,evaluate_name)
            
            log_paths.append(log_path)
            result_paths.append(result_path)
            report_paths.append(report_path)
    else:

        with concurrent.futures.ThreadPoolExecutor(max_workers=parallel) as executor:
            futures = {executor.submit(macro_flow, name, def_path, evaluate_name): name for name, def_path in case.items()}
            for future in concurrent.futures.as_completed(futures):
                log_path, result_path, report_path = future.result()
                log_paths.append(log_path)
                result_paths.append(result_path)
                report_paths.append(report_path)


    move2final(evaluate_name,log_paths,result_paths,report_paths)

    final_result_dir=os.path.join("benchmarking_result",evaluate_name)


    


    metrics_dict=getMetrics(final_result_dir)
    
    normalized_metrics,average_metrics=normalize_metric(metrics_dict)

    metric_path=os.path.join(final_result_dir,"metrics.json")
    normalized_path=os.path.join(final_result_dir,"normalized_metrics.json")
    average_path=os.path.join(final_result_dir,"average_result.json")

    with open(metric_path,"w") as f:
        json.dump(metrics_dict,f,indent=4)

    

    with open(normalized_path,"w") as f:
        json.dump(normalized_metrics,f,indent=4)

    with open(average_path,"w") as f:
        json.dump(average_metrics,f,indent=4)

    return 0

def global_mode(config:dict):

    parallel=config["parallel"]
    evaluate_name=config["evaluate_name"]

    case:dict=config["case"]
    log_paths=[]
    result_paths=[]
    report_paths=[]

    if not parallel:

        for name,def_path in case.items():
            log_path,result_path,report_path=global_flow(name,def_path,evaluate_name)
            
            log_paths.append(log_path)
            result_paths.append(result_path)
            report_paths.append(report_path)
    else:

        with concurrent.futures.ThreadPoolExecutor(max_workers=parallel) as executor:
            futures = {executor.submit(global_flow, name, def_path, evaluate_name): name for name, def_path in case.items()}
            for future in concurrent.futures.as_completed(futures):
                log_path, result_path, report_path = future.result()
                log_paths.append(log_path)
                result_paths.append(result_path)
                report_paths.append(report_path)


    move2final(evaluate_name,log_paths,result_paths,report_paths)

    final_result_dir=os.path.join("benchmarking_result",evaluate_name)


    


    metrics_dict=getMetrics(final_result_dir)
    
    normalized_metrics,average_metrics=normalize_metric(metrics_dict)

    metric_path=os.path.join(final_result_dir,"metrics.json")
    normalized_path=os.path.join(final_result_dir,"normalized_metrics.json")
    average_path=os.path.join(final_result_dir,"average_result.json")

    with open(metric_path,"w") as f:
        json.dump(metrics_dict,f,indent=4)

    with open(normalized_path,"w") as f:
        json.dump(normalized_metrics,f,indent=4)

    with open(average_path,"w") as f:
        json.dump(average_metrics,f,indent=4)


    return 0



def mixsize_mode(config:dict):
    parallel=config["parallel"]
    evaluate_name=config["evaluate_name"]

    case:dict=config["case"]
    log_paths=[]
    result_paths=[]
    report_paths=[]

    if not parallel:

        for name,def_path in case.items():
            log_path,result_path,report_path=mixsize_flow(name,def_path,evaluate_name)
            
            log_paths.append(log_path)
            result_paths.append(result_path)
            report_paths.append(report_path)
    else:

        with concurrent.futures.ThreadPoolExecutor(max_workers=parallel) as executor:
            futures = {executor.submit(mixsize_flow, name, def_path, evaluate_name): name for name, def_path in case.items()}
            for future in concurrent.futures.as_completed(futures):
                log_path, result_path, report_path = future.result()
                log_paths.append(log_path)
                result_paths.append(result_path)
                report_paths.append(report_path)


    move2final(evaluate_name,log_paths,result_paths,report_paths)

    final_result_dir=os.path.join("benchmarking_result",evaluate_name)


    final_logs_dir=os.path.join(final_result_dir,"logs")


    metrics_dict=getMetrics(final_logs_dir)
    
    normalized_metrics,average_metrics=normalize_metric(metrics_dict)

    metric_path=os.path.join(final_result_dir,"metrics.json")
    normalized_path=os.path.join(final_result_dir,"normalized_metrics.json")
    average_path=os.path.join(final_result_dir,"average_result.json")

    with open(metric_path,"w") as f:
        json.dump(metrics_dict,f,indent=4)

    with open(normalized_path,"w") as f:
        json.dump(normalized_metrics,f,indent=4)

    with open(average_path,"w") as f:
        json.dump(average_metrics,f,indent=4)


    
    return 0

def benchmarking(config:dict):
    mode=config["mode"]
    

    if mode=="macro" or mode==1:
        macro_mode(config)

    elif mode=="global" or mode==2:
        global_mode(config)

    elif mode=="mixsize"or mode==3:
        mixsize_mode(config)




if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python script.py config.json")
    else:
        config_path=sys.argv[1]

    with open(config_path,"r") as f:
        config=json.load(f)

    benchmarking(config)





