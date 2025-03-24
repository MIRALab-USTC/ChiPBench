import os
import re
import json


def get_units(data):
    time_units=data.get("run__flow__platform__time_units",None)
    distance_units=data.get("run__flow__platform__distance_units",None)
    power_units=data.get("run__flow__platform__power_units",None)
    unit_dict={"time_units":time_units,"distance_units":distance_units,"power_units":power_units}
    return unit_dict


def sum_power_totals(data):
    
    internal_total = data.get("finish__power__internal__total", None)
    switching_total = data.get("finish__power__switching__total", None)
    leakage_total = data.get("finish__power__leakage__total", None)

    if internal_total is None or switching_total is None or leakage_total is None:
        return None

    if not isinstance(internal_total, (int, float)):
        return None
    if not isinstance(switching_total, (int, float)):
        return None
    if not isinstance(leakage_total, (int, float)):
        return None

    return internal_total + switching_total + leakage_total

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



def get_totalHpwl(file_content):
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
        return None
        raise ValueError("Table start pattern not found in the file")
    table_start_index = match.end()
    table_content = content[table_start_index:]
    # Find the Total line and extract the Usage percentage
    total_line_pattern = r'Total\s+(\d+)\s+(\d+)\s+(\d+\.\d+)%\s+(\d+)\s*/\s*(\d+)\s*/\s*(\d+)'
    total_match = re.search(total_line_pattern, table_content)
    if not total_match:
        raise ValueError("Total usage percentage not found in the table")
    total_usage = total_match.group(3)
    return float(total_usage.replace("%", "")) / 100


def get_grt_data(text: str) -> dict:
    """
    Parse specific GRT (Global Routing) information from the given text.

    :param text: The complete content of a text file as a single string.
    :return: A dictionary that consolidates parsed routing resources analysis and final congestion report data.
    """

    # This dictionary will hold the final merged result.
    parsed_data = {}

    # ---------------------------------------------------------
    # 1) Parse "[INFO GRT-0053] Routing resources analysis" block
    # ---------------------------------------------------------
    # We try to locate the text block after "[INFO GRT-0053]" until the line of dashes.
    # Then we extract each line within that block to parse:
    #   Layer (e.g., "metal1"), Direction (Horizontal/Vertical), etc.
    #
    # We only need the layer name and routing direction from this section.
    # Direction will be stored as "H" if "Horizontal", "V" if "Vertical".
    # Any additional data in that block is ignored.
    # If this block is missing, no exception is raised; we just skip it.

    # Regex pattern to capture the lines between the first and second "-----" lines
    # after encountering "[INFO GRT-0053] Routing resources analysis:"
    # We use DOTALL to allow matches over multiple lines.
    pattern_0053_block = re.compile(
        r'\[INFO\s+GRT-0053\]\s*Routing\s+resources\s+analysis:.*?^-+\n(.*?)^-+',
        re.DOTALL | re.MULTILINE
    )

    match_0053_block = pattern_0053_block.search(text)
    if match_0053_block:
        block_0053_content = match_0053_block.group(1)
        # Parse each line in the extracted block.
        # Expected format:
        # metal1     Horizontal    5609898    2054336    63.38%
        # metal2     Vertical      3570000    2050939    42.55%
        # ...
        #
        # We focus on capturing two groups: layer name and direction.
        # We'll ignore the other columns, but be flexible about spacing.
        pattern_0053_line = re.compile(r'^\s*(\S+)\s+(Horizontal|Vertical)\s+', re.MULTILINE)
        for line_match in pattern_0053_line.finditer(block_0053_content):
            layer_name = line_match.group(1)
            direction_text = line_match.group(2)
            direction = "H" if direction_text == "Horizontal" else "V"
            # Initialize dictionary for this layer if not present
            if layer_name not in parsed_data:
                parsed_data[layer_name] = {}
            parsed_data[layer_name]["direction"] = direction

    # ---------------------------------------------------------
    # 2) Parse "[INFO GRT-0096] Final congestion report" block
    # ---------------------------------------------------------
    # We try to locate the text block after "[INFO GRT-0096]" until the line of dashes.
    # Then we extract each line within that block to parse:
    #   Layer, Resource, Demand, Usage (%), MaxH, MaxV, overflow
    #
    # After extracting these data, we attach them to the corresponding layers.
    # If a layer is missing from the earlier part, we still add these values.
    # If this block is missing, we skip it.
    pattern_0096_block = re.compile(
        r'\[INFO\s+GRT-0096\]\s*Final\s+congestion\s+report:.*?^-+\n(.*?)^-+',
        re.DOTALL | re.MULTILINE
    )

    match_0096_block = pattern_0096_block.search(text)
    if match_0096_block:
        block_0096_content = match_0096_block.group(1)
        # Parse each line in the extracted block.
        # Expected format:
        # metal1          0              0              0.00%             0 /  0 /  0
        # metal2     2054336         742576            36.15%             0 /  0 /  0
        # ...
        # We will capture (layer, resource, demand, usage, maxH, maxV, overflow).
        #
        # Notice that usage might contain a percentage symbol. We remove it or parse as float.
        # Also, MaxH, MaxV, and overflow are separated by slashes.
        pattern_0096_line = re.compile(
            r'^\s*(\S+)\s+'            # Layer name (group 1)
            r'(\d+)\s+'                # Resource (group 2)
            r'(\d+)\s+'                # Demand (group 3)
            r'([\d\.]+)%\s+'           # Usage (group 4, w/o %)
            r'(\d+)\s*/\s*(\d+)\s*/\s*(\d+)\s*$',  # MaxH/MaxV/overflow (groups 5,6,7)
            re.MULTILINE
        )

        for line_match in pattern_0096_line.finditer(block_0096_content):
            layer_name = line_match.group(1)
            resource = int(line_match.group(2))
            demand = int(line_match.group(3))
            usage = float(line_match.group(4))
            max_h = int(line_match.group(5))
            max_v = int(line_match.group(6))
            overflow = int(line_match.group(7))

            if layer_name not in parsed_data:
                parsed_data[layer_name] = {}
            parsed_data[layer_name]["Resource"] = resource
            parsed_data[layer_name]["Demand"] = demand
            parsed_data[layer_name]["Usage"] = usage
            parsed_data[layer_name]["MaxH"] = max_h
            parsed_data[layer_name]["MaxV"] = max_v
            parsed_data[layer_name]["overflow"] = overflow

    # Return the consolidated dictionary with all parsed info.
    return parsed_data

def get_congestion(content):
    grt_data=get_grt_data(content)
    H_layers=[]
    V_layers=[]
    MaxH=0
    MaxV=0
    overflow=0
    for layer,data in grt_data.items():
        if data["Resource"] == 0:
            continue
        if data["direction"]=="H":
            H_layers.append(layer)
        else:
            V_layers.append(layer)
        MaxH+=data["MaxH"]
        MaxV+=data["MaxV"]
        overflow+=data["overflow"]
    
    route_usage_V=0
    route_usage_H=0
    for layer in H_layers:
        route_usage_H+=grt_data[layer]["Usage"]
    for layer in V_layers:
        route_usage_V+=grt_data[layer]["Usage"]

    route_usage_V/=len(V_layers)
    route_usage_H/=len(H_layers)
    return route_usage_V/100,route_usage_H/100,MaxH,MaxV,overflow


def load_Json(Json):
    try:
        with open(Json, 'r', encoding='utf-8') as file:
            data = json.load(file)
            return data
    except FileNotFoundError:
        
        return {}  
    
def load_file(input_file):
    try:
        with open(input_file, 'r', encoding='utf-8') as file:
            data = file.read()
            return data
    except FileNotFoundError:
        
        return ""  

def get_Metric_in(finalJson, routeJson, placedpLog,gproutefile,dr_route_path,macro_path=""):


    final=load_Json(finalJson)
    route=load_Json(routeJson)
    place=load_file(placedpLog)
    gproute=load_file(gproutefile)
    dr_route=load_Json(dr_route_path)
    macro=load_Json(macro_path)
    # with open(finalJson, 'r', encoding='utf-8') as file:
    #     final = json.load(file)

    # with open(routeJson, 'r', encoding='utf-8') as file:
    #     route = json.load(file)

    # with open(placedpLog, 'r', encoding='utf-8') as file:
    #     place = file.read()

    # with open(gproutefile, 'r', encoding='utf-8') as file:
    #     gproute = file.read()

    metric = {}
    if "hpwl" in macro:
        metric["MHpwl"] = macro["hpwl"]
    if "regularity" in macro:
        metric["Regularity"] = macro["regularity"]
    # metric["DataFlow"]=macro["dataflow"]
    metric["HPWL"] = get_totalHpwl(place)
    metric["Wirelength"] = get_wirelength(route)
    metric["Congestion(V)"],metric["Congestion(H)"],metric["MaxH"],metric["MaxV"],metric["overflow"]=get_congestion(gproute)
    metric["Congestion"]=get_usage(gproute)
    metric["Route_DRC"]=dr_route["detailedroute__route__drc_errors"]
    metric["Power"] = sum_power_totals(final)
    metric["WNS"], metric["TNS"] = get_wns_tns(final)
    metric["NVP"]=get_nvp(final)
    metric["Area"] = get_area(final)
    metric["unit"]=get_units(final)
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

    for entry in os.listdir(base_dir):
        parent_dir_name=entry
        root = os.path.join(base_dir, entry,"base")
        if os.path.isdir(root):
            report_files[parent_dir_name] = {
                    "report": os.path.join(root, '6_report.json'),
                    "route": os.path.join(root, '5_2_route.json'),
                    "place": os.path.join(root, '3_5_place_dp.log'),
                    "gp_route": os.path.join(root,"5_1_grt.log")
                }

    # for root, dirs, files in os.walk(base_dir):
    #     # Check if all three required files are in the current directory
    #     if all(f in files for f in ['6_report.json', '5_2_route.json', '3_5_place_dp.log']):
    #         parent_dir_name = os.path.basename(os.path.dirname(root))


    #         report_files[parent_dir_name] = {
    #             "report": os.path.join(root, '6_report.json'),
    #             "route": os.path.join(root, '5_2_route.json'),
    #             "place": os.path.join(root, '3_5_place_dp.log'),
    #             "gp_route": os.path.join(root,"5_1_grt.log")
    #         }

    return report_files

def get_all_metric_json(report_files):
    all_metric_json = {}

    
    for case_name, report_file in report_files.items():
        metric = get_Metric_in(report_file["report"], report_file["route"], report_file["place"],report_file["gp_route"])
        all_metric_json[case_name] = metric

    return all_metric_json



def getMetrics(dir_path):
    report_files=find_reports_in_dirs(dir_path)
    #print(report_files)
    metric_dict=get_all_metric_json(report_files)
    #print(metric_dict)

    return metric_dict

def get_metrics_single(log_path):

    report_path=os.path.join(log_path,"6_report.json")
    route_path=os.path.join(log_path,"5_2_route.json")
    place_path=os.path.join(log_path,"3_5_place_dp.log")
    gp_route_path=os.path.join(log_path,"5_1_grt.log")
    dr_route_path=os.path.join(log_path,"5_2_route.json")
    floorplan_path=os.path.join(log_path,"2_1_floorplan.json")
    macro_path=os.path.join(log_path,"macro.json")
    
    metric=get_Metric_in(report_path,route_path,place_path,gp_route_path,dr_route_path,macro_path)
    return metric

if __name__ == "__main__":
    metric=get_metrics_single("/workspace/afix/test/ChiPBench/flow/logs/nangate45/bp/autodmp")
    print(metric)