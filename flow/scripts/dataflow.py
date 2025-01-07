from openroad import Tech, Design, Timing
import odb
from tqdm import tqdm
import numpy as np
from Graph_util import build_directed_graph,getDataFlow_main


def create_graph(block:odb.dbBlock):
    inst_set=block.getInsts()
    nets=block.getNets()
    nodes_info={}
    nets_info=[]
    for inst in tqdm(inst_set,desc="create nodes"):
        inst:odb.dbInst=inst
        node_info={}
        
        is_register=(inst.findITerm("CK") is not None)
        node_info["is_register"]=is_register
        node_info["isMacro"]=inst.isBlock()
        nodes_info[inst.getName()]=node_info

    for net in tqdm(nets,desc="create nets"):
        net:odb.dbNet=net
        net_info={}
        net_iterms=net.getITerms()
        is_clock_net=False
        has_output = False
        has_input = False
        for iterm in net_iterms:
            if iterm.getIoType() == "OUTPUT":
                has_output = True
            elif iterm.getIoType() == "INPUT":
                has_input = True
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

        nets_info.append(net_info)

    # for net in nets_info:
    #     print(net)

    G=build_directed_graph(nodes_info,nets_info)
    return G

def distanceM2M(macro1:odb.dbInst,macor2:odb.dbInst):
    box1:odb.dbBox=macro1.getBBox()
    box2:odb.dbBox=macor2.getBBox()
    box1_cx=(box1.xMax()+box1.xMin())/2
    box1_cy=(box1.yMax()+box1.yMin())/2
    box2_cx=(box2.xMax()+box2.xMin())/2
    box2_cy=(box2.yMax()+box2.yMin())/2
    return np.sqrt((box1_cx-box2_cx)**2+(box1_cy-box2_cy)**2)



def getdataflow(block:odb.dbBlock,depth=10):
    data_flow=0
    G=create_graph(block)
    inst_set=block.getInsts()
    macro_insts=[inst for inst in inst_set if inst.isBlock()]
    macro_names=[inst.getName() for inst in macro_insts]
    _, macro_paths_data_flow_array=getDataFlow_main(G,macro_names,depth=depth)
    normalized_data_flow = macro_paths_data_flow_array / np.sum(macro_paths_data_flow_array)*2
    for i in range(len(macro_names)):
        for j in range(i+1,len(macro_names)):
            distance=distanceM2M(macro_insts[i],macro_insts[j])
            data_flow+=normalized_data_flow[i,j]*distance

    data_flow_um=block.dbuToMicrons(data_flow)
    return data_flow_um




if __name__=="__main__":
    tech=Tech()
    design=Design(tech)
    design.readDb("/workspace/afix/test/ChiPBench/flow/results/nangate45/bp_fe/bbo/2_3_floorplan_macro.odb")
    block=design.getBlock()
    data_flow=getdataflow(block,depth=8)
    print(data_flow)