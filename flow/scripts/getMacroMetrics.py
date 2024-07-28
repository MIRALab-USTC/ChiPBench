from openroad import Tech, Design, Timing
import odb
import random
import os
import json
from dataflow import getdataflow
import numpy as np

tech = Tech()

results_dir=os.getenv('RESULTS_DIR')
if results_dir:
    print(f"results_dir environment variable: {results_dir}")
else:
    print("results_dir environment variable is not set")


design:Design = Design(tech)

db_path=os.path.join(results_dir,"2_3_floorplan_macro.odb")

design.readDb(db_path)

design_block:odb.dbBlock = design.getBlock()



def getMHPWL_net(net:odb.dbNet):
    items = net.getITerms()
    bterms=net.getBTerms()
    x_min = float('inf')
    y_min = float('inf')
    x_max = float('-inf')
    y_max = float('-inf')

    for bterm in bterms:
        bterm:odb.dbBTerm = bterm
        bterm_box:odb.Rect=bterm.getBBox()
        x_min = min(x_min, bterm_box.xMin())
        y_min = min(y_min, bterm_box.yMin())
        x_max = max(x_max, bterm_box.xMin())
        y_max = max(y_max, bterm_box.yMin())
    
    for item in items:
        item:odb.dbITerm = item
        iterm_box:odb.Rect = item.getBBox()
        inst:odb.dbInst = item.getInst()
        if inst.getMaster().isBlock():  
            x_min = min(x_min, iterm_box.xMin())
            y_min = min(y_min, iterm_box.yMin())
            x_max = max(x_max, iterm_box.xMin())
            y_max = max(y_max, iterm_box.yMin())
    
    if x_min == float('inf') or x_max == float('-inf') or y_min == float('inf') or y_max == float('-inf'):
        return 0
    # print(f"x_min: {x_min}, y_min: {y_min}, x_max: {x_max}, y_max: {y_max}")

    hpwl=x_max-x_min+y_max-y_min
    
    return hpwl


def getMHPWL(design_block:odb.dbBlock):
    net_set=design_block.getNets()
    hpwl=0
    for net in net_set:
        net:odb.dbNet = net
        hpwl+=getMHPWL_net(net)
    return hpwl

def getRegularity(design_block: odb.dbBlock) -> int:
    core_area: odb.dbBox = design_block.getCoreArea()
    x_max = core_area.xMax()
    y_max = core_area.yMax()

    regularity_total = 0
    inst_set = design_block.getInsts()

    for inst in inst_set:
        inst: odb.dbInst = inst
        inst_master: odb.dbMaster = inst.getMaster()
        if inst_master.isBlock():
            x = inst.getLocation()[0]
            y = inst.getLocation()[1]
            regularity = min(x, x_max - x) + min(y, y_max - y)
            regularity_total += regularity

    return regularity_total


hpwl=getMHPWL(design_block)
regularity=getRegularity(design_block)


logs_dir=os.getenv('LOG_DIR')

hpwl_um=design_block.dbuToMicrons(hpwl)
regularity_um=design_block.dbuToMicrons(regularity)
macro_json=os.path.join(logs_dir,"macro.json")
depth=8

# dataflow=getdataflow(design_block,depth=depth)
# while dataflow is None or np.isnan(dataflow):
#     depth += 1
#     dataflow = getdataflow(design_block, depth=depth)


data={}
data["hpwl"]=hpwl_um
data["regularity"]=regularity_um

# data["dataflow"]=dataflow
with open(macro_json,"w") as f:
    json.dump(data,f,indent=4)

# print(f"hpwl_dbu: {hpwl}")
# print(f"hpwl_um: {hpwl/2000}")
