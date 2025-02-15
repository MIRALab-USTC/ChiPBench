from openroad import Tech, Design, Timing
import odb
import random
import os



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
core_area:odb.dbBox = design_block.getCoreArea()
core_area_list = [core_area.xMin(),core_area.yMin(),core_area.xMax(),core_area.yMax()]

print(core_area_list)

inst_set = design_block.getInsts()
x_l_list = []
y_l_list = []
x_h_list = []
y_h_list = []
for inst in inst_set:
    inst:odb.dbInst = inst
    inst_master:odb.dbMaster = inst.getMaster()
    # inst.setLocation(0,0)
    if inst_master.isBlock():
        inst.setPlacementStatus("PLACED")
        y=inst.getLocation()[1]
        orient=inst.getOrient()
        if orient=="R0":
            y=round((y-70)/280)*280+70
        elif orient=="R180":
            y=round((y+70)/280)*280-70
        elif orient=="MX":
            y=round((y+70)/280)*280-70
        elif orient=="MY":
            y=round((y-70)/280)*280+70
        print(orient)
        # y=round((y-70)/280)*280+70
        inst.setLocation(inst.getLocation()[0],y)
        inst.setPlacementStatus("FIRM")
        bbox:odb.Rect = inst.getBBox()
        x_l_list.append(bbox.xMin())
        y_l_list.append(bbox.yMin())
        x_h_list.append(bbox.xMax())
        y_h_list.append(bbox.yMax())
    else:
        # continue
        inst.setLocation(int(core_area.xMax()/2),int(core_area.yMax()/2))
        inst.setOrient("R0")



x_max=max(x_h_list)
x_min=min(x_l_list)
y_max=max(y_h_list)
y_min=min(y_l_list)

print(x_max,x_min,y_max,y_min)

# if x_max>core_area_list[2] or x_min<core_area_list[0] or y_max>core_area_list[3] or y_min<core_area_list[1]:
#     print("instance is out of core area")
# else:
#     print("instance is within core area")


# if x_min<core_area_list[0] and x_max>core_area_list[2]:
#     x_add=core_area_list[0]-x_min

# if y_min<core_area_list[1] and y_max>core_area_list[3]:


# if x_min<core_area_list[0]:
#     x_add=core_area_list[0]-x_min

# if x_max>core_area_list[2]:
#     x_add=core_area_list[2]-x_max

# if y_min<core_area_list[1]:
#     y_add=core_area_list[1]-y_min

# if y_max>core_area_list[3]:
#     y_add=core_area_list[3]-y_max
    

inst_width = x_max - x_min
inst_height = y_max - y_min
print("inst_width:",inst_width)
print("inst_height:",inst_height)

x_shift_applied = False
y_shift_applied = False

if inst_width <= (core_area_list[2] - core_area_list[0]) and (x_min < core_area_list[0] or x_max > core_area_list[2]):
    x_shift = core_area_list[0] - x_min if x_min < core_area_list[0] else core_area_list[2] - x_max
    for inst in inst_set:
        inst:odb.dbInst = inst
        inst_master:odb.dbMaster = inst.getMaster()
        if inst_master.isBlock():
            inst.setPlacementStatus("PLACED")
            inst.setLocation(inst.getLocation()[0] + x_shift, inst.getLocation()[1])
            inst.setPlacementStatus("FIRM")
    x_shift_applied = True

if inst_height <= (core_area_list[3] - core_area_list[1]) and (y_min < core_area_list[1] or y_max > core_area_list[3]):
    y_shift = core_area_list[1] - y_min if y_min < core_area_list[1] else core_area_list[3] - y_max
    for inst in inst_set:
        inst:odb.dbInst = inst
        inst_master:odb.dbMaster = inst.getMaster()
        if inst_master.isBlock():
            inst.setPlacementStatus("PLACED")
            y=inst.getLocation()[1]+y_shift
            orient=inst.getOrient()
            if orient=="R0":
                y=round((y-70)/280)*280+70
            elif orient=="R180":
                y=round((y+70)/280)*280-70
            elif orient=="MX":
                y=round((y+70)/280)*280-70
            elif orient=="MY":
                y=round((y-70)/280)*280+70
            # y=round((y-70)/280)*280+70
            inst.setLocation(inst.getLocation()[0], y)
            inst.setPlacementStatus("FIRM")
            # print("y_shift:",y_shift)
    y_shift_applied = True

if not (x_shift_applied and y_shift_applied):
    for inst in inst_set:
        inst:odb.dbInst = inst
        inst_master:odb.dbMaster = inst.getMaster()
        if inst_master.isBlock():
            bbox:odb.Rect = inst.getBBox()
            inst.setPlacementStatus("PLACED")
            if bbox.xMin() < core_area_list[0]:
                inst.setLocation(core_area_list[0], inst.getLocation()[1])
            elif bbox.xMax() > core_area_list[2]:
                inst.setLocation(core_area_list[2] - (bbox.xMax() - bbox.xMin()), inst.getLocation()[1])

            if bbox.yMin() < core_area_list[1]:
                y=core_area_list[1]
                orient=inst.getOrient()
                if orient=="R0":
                    y=round((y-70)/280)*280+70
                elif orient=="R180":
                    y=round((y+70)/280)*280-70
                elif orient=="MX":
                    y=round((y+70)/280)*280-70
                elif orient=="MY":
                    y=round((y-70)/280)*280+70
                inst.setLocation(inst.getLocation()[0], y)
            elif bbox.yMax() > core_area_list[3]:
                y=core_area_list[3]
                orient=inst.getOrient()
                if orient=="R0":
                    y=round((y-70)/280)*280+70
                elif orient=="R180":
                    y=round((y+70)/280)*280-70
                elif orient=="MX":
                    y=round((y+70)/280)*280-70
                elif orient=="MY":
                    y=round((y-70)/280)*280+70
                inst.setLocation(inst.getLocation()[0], y)
            inst.setPlacementStatus("FIRM")

design.writeDb(db_path)
    
