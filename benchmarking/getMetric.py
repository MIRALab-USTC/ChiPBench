import os
import re
import json

def sum_power_totals(data):
    
    internal_total = data.get("finish__power__internal__total", None)
    switching_total = data.get("finish__power__switching__total", None)

    if internal_total is None or switching_total is None:
        return None

    if not isinstance(internal_total, (int, float)):
        return None
    if not isinstance(switching_total, (int, float)):
        return None

    return internal_total + switching_total

def get_wns_tns(data):
    
    tns = data.get("finish__timing__setup__tns", None)
    wns = data.get("finish__timing__setup__ws", None)

    if wns is None or tns is None:
        return None, None

    if not isinstance(wns, (int, float)):
        return None, None
    if not isinstance(tns, (int, float)):
        return None, None

    return wns, tns

def get_area(data):
    
    area = data.get("finish__design__instance__area__stdcell", None)

    if area is None:
        return None

    if not isinstance(area, (int, float)):
        return None

    return area

def get_wirelength(data):
   
    wirelength = data.get("detailedroute__route__wirelength", None)

    if wirelength is None:
        return None

    if not isinstance(wirelength, (int, float)):
        return None

    return wirelength

def get_nvp(data):
    
    nvp = data.get("finish__timing__drv__setup_violation_count", None)

    if nvp is None:
        return None

    if not isinstance(nvp, (int, float)):
        return None

    return nvp



def get_cellHpwl(file_content):
    try:
        # Define the regex pattern to match the specific string and capture the number
        pattern = r"\[INFO DPL-0022\] HPWL after\s+([0-9]+\.[0-9]+) u"
        
        # Search for the pattern in the file content
        match = re.search(pattern, file_content)
        
        if match:
            # Extract the matched number and convert it to float
            hpwl_value = float(match.group(1))
            return hpwl_value
        else:
            return None
    
    except re.error:
        return None

def get_usage(content):
    
    # Find the specific table
    table_start_pattern = r'\[INFO GRT-0096\] Final congestion report:'
    match = re.search(table_start_pattern, content)
    if not match:
        raise ValueError("Table start pattern not found in the file")
    table_start_index = match.end()
    table_content = content[table_start_index:]
    # Find the Total line and extract the Usage percentage
    total_line_pattern = r'Total\s+\d+\s+\d+\s+(\d+\.\d+%)'
    total_match = re.search(total_line_pattern, table_content)
    if not total_match:
        raise ValueError("Total usage percentage not found in the table")
    total_usage = total_match.group(1)
    return float(total_usage.replace("%", "")) / 100



def get_Metric_in(finalJson, routeJson, placedpLog,gproutefile):
    with open(finalJson, 'r', encoding='utf-8') as file:
        final = json.load(file)

    with open(routeJson, 'r', encoding='utf-8') as file:
        route = json.load(file)

    with open(placedpLog, 'r', encoding='utf-8') as file:
        place = file.read()

    with open(gproutefile, 'r', encoding='utf-8') as file:
        gproute = file.read()

    metric = {}
    metric["HPWL"] = get_cellHpwl(place)
    metric["Wirelength"] = get_wirelength(route)
    metric["Congestion"]=get_usage(gproute)
    metric["Power"] = sum_power_totals(final)
    metric["WNS"], metric["TNS"] = get_wns_tns(final)
    metric["NVP"]=get_nvp(final)
    metric["Area"] = get_area(final)

    return metric

def get_substring_after_underscore(input_string):
    
    underscore_index = input_string.find('_')
    
    if underscore_index != -1:
        
        result = input_string[underscore_index + 1:]
        return result
    else:
        
        return input_string



def find_reports_in_dirs(base_dir):
    report_files = {}

    for root, dirs, files in os.walk(base_dir):
        # Check if all three required files are in the current directory
        if all(f in files for f in ['6_report.json', '5_2_route.json', '3_5_place_dp.log']):
            parent_dir_name = os.path.basename(os.path.dirname(root))


            report_files[parent_dir_name] = {
                "report": os.path.join(root, '6_report.json'),
                "route": os.path.join(root, '5_2_route.json'),
                "place": os.path.join(root, '3_5_place_dp.log'),
                "gp_route": os.path.join(root,"5_1_grt.log")
            }

    return report_files

def get_all_metric_json(report_files):
    all_metric_json = {}

    
    for case_name, report_file in report_files.items():
        metric = get_Metric_in(report_file["report"], report_file["route"], report_file["place"],report_file["gp_route"])
        all_metric_json[case_name] = metric

    return all_metric_json



def getMetrics(dir_path):
    report_files=find_reports_in_dirs(dir_path)
    metric_dict=get_all_metric_json(report_files)

    return metric_dict


