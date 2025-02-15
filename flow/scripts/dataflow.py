from openroad import Tech, Design, Timing
import odb
from tqdm import tqdm
import numpy as np
from Graph_util import build_directed_graph,getDataFlow_main,search_pathsM2C
import os
import json

def create_graph(block:odb.dbBlock):
    inst_set=block.getInsts()
    nets=block.getNets()
    bterms=block.getBTerms()
    nodes_info={}
    nets_info=[]
    for inst in tqdm(inst_set,desc="create nodes"):
        inst:odb.dbInst=inst
        node_info={}
        
        is_register=(inst.findITerm("CK") is not None)
        node_info["is_register"]=is_register
        node_info["isMacro"]=inst.isBlock()
        node_info["is_port"]=False
        nodes_info[inst.getName()]=node_info

    for bterm in tqdm(bterms,desc="create bterms"):
        bterm:odb.dbBTerm=bterm
        bterm_name=bterm.getName()
        node_info={}
        node_info["is_port"]=True
        node_info["is_register"]=False
        node_info["isMacro"]=False
        nodes_info[bterm_name]=node_info


    for net in tqdm(nets,desc="create nets"):
        net:odb.dbNet=net
        net_info={}
        net_iterms=net.getITerms()
        net_bterms=net.getBTerms()
        is_clock_net=False
        has_output = False
        has_input = False
        for iterm in net_iterms:
            if iterm.getIoType() == "OUTPUT":
                has_output = True
            elif iterm.getIoType() == "INPUT":
                has_input = True
        for bterm in net_bterms:
            bterm:odb.dbBTerm=bterm
            if bterm.getIoType()=="OUTPUT":
                has_input=True
            elif bterm.getIoType()=="INPUT":
                has_output=True
        
        if not (has_output and has_input):
            continue
        
        net_info["inputs"]=[]
        net_info["output"]=None
        for net_iterm in net_iterms:
            net_iterm:odb.dbITerm=net_iterm
            net_iterm_name=net_iterm.getName()
            net_iterm_master_name=net_iterm_name.split("/")[-1]
            if net_iterm_master_name=="CK":
                is_clock_net=True
                break
            if net_iterm.getIoType()=="OUTPUT":
                net_info["output"]=net_iterm.getInst().getName()
            else:
                net_info["inputs"].append(net_iterm.getInst().getName())
        if is_clock_net:
            continue

        for bterm in net_bterms:
            bterm:odb.dbBTerm=bterm
            bterm_name=bterm.getName()
            if bterm.getIoType()=="INPUT":
                net_info["output"]=bterm_name
            else:
                net_info["inputs"].append(bterm_name)


        nets_info.append(net_info)

    # for net in nets_info:
    #     print(net)

    G=build_directed_graph(nodes_info,nets_info)
    return G

def distanceM2M(macro1,macor2):
    box1=macro1.getBBox()
    box2=macor2.getBBox()
    box1_cx=(box1.xMax()+box1.xMin())/2
    box1_cy=(box1.yMax()+box1.yMin())/2
    box2_cx=(box2.xMax()+box2.xMin())/2
    box2_cy=(box2.yMax()+box2.yMin())/2
    return np.sqrt((box1_cx-box2_cx)**2+(box1_cy-box2_cy)**2)

def getDataFlow_M2C(block:odb.dbBlock,depth=10):
    data_flow=0
    G=create_graph(block)
    inst_set=block.getInsts()
    bterms=block.getBTerms()
    macro_insts=[inst for inst in inst_set if inst.isBlock()]
    macro_names=[inst.getName() for inst in macro_insts]
    bterm_names=[bterm.getName() for bterm in bterms]
    macro_names.extend(bterm_names)
    macro_insts.extend(bterms)
    
    macro_name_to_index = {}
    for i, macro_name in enumerate(macro_names):
        macro_name_to_index[macro_name] = i


    macro2register={}

    print("M2C")
    for i, macro_name in enumerate(macro_names):
        macro2register[macro_name]=[]
        paths = search_pathsM2C(G, macro_name, 10)
        for j, path in enumerate(paths):
            end_node = path[-1]
            macro2register[macro_name].append(end_node)
        print(f"{macro_name} has {len(paths)} paths")
    print("finish M2C")

    weighted_sum = 0
    weights = []
    lengths = []
    
    for i, macro_name in enumerate(macro_names):
        for register_name in macro2register[macro_name]:
            register_cell = block.findInst(register_name)
            length = distanceM2M(macro_insts[i], register_cell)
            lengths.append(length)
            weights.append(0.5)
    
    _, macro_paths_data_flow_array = getDataFlow_main(G, macro_names, depth=depth)
    for i in range(len(macro_names)):
        for j in range(i+1, len(macro_names)):
            distance = distanceM2M(macro_insts[i], macro_insts[j])
            lengths.append(distance)
            weights.append(macro_paths_data_flow_array[i,j])
    
    weights = np.array(weights)
    weights = weights / np.sum(weights)
    weighted_sum = np.sum(np.array(lengths) * weights)
    data_flow_um=block.dbuToMicrons(weighted_sum)

    return data_flow_um

    # print(lenght_and_weight)


def getdataflow(block:odb.dbBlock,depth=10):
    data_flow=0
    G=create_graph(block)
    inst_set=block.getInsts()
    bterms=block.getBTerms()
    macro_insts=[inst for inst in inst_set if inst.isBlock()]
    macro_names=[inst.getName() for inst in macro_insts]
    bterm_names=[bterm.getName() for bterm in bterms]
    macro_names.extend(bterm_names)
    macro_insts.extend(bterms)
    _, macro_paths_data_flow_array=getDataFlow_main(G,macro_names,depth=depth)
    normalized_data_flow = macro_paths_data_flow_array / np.sum(macro_paths_data_flow_array)*2
    for i in range(len(macro_names)):
        for j in range(i+1,len(macro_names)):
            distance=distanceM2M(macro_insts[i],macro_insts[j])
            data_flow+=normalized_data_flow[i,j]*distance

    data_flow_um=block.dbuToMicrons(data_flow)
    return data_flow_um




if __name__=="__main__":
    tech = Tech()

    results_dir=os.getenv('RESULTS_DIR')
    if results_dir:
        print(f"results_dir environment variable: {results_dir}")
    else:
        print("results_dir environment variable is not set")


    design:Design = Design(tech)

    db_path=os.path.join(results_dir,"3_3_place_gp.odb")

    design.readDb(db_path)

    design_block:odb.dbBlock = design.getBlock()
    logs_dir=os.getenv('LOG_DIR')

    macro_json=os.path.join(logs_dir,"macro.json")
    with open(macro_json,"r") as f:
        data=json.load(f)
    depth=10

    dataflow=getDataFlow_M2C(design_block,depth=depth)
    while dataflow is None or np.isnan(dataflow):
        depth += 1
        dataflow = getDataFlow_M2C(design_block, depth=depth)



    data["dataflow"]=dataflow
    with open(macro_json,"w") as f:
        json.dump(data,f,indent=4)
