import os
import sys
import time
import shutil
import numpy as np
from openroad import Tech, Design, Timing
import odb
import json
# import logging
# import Params
# import PlaceDB


def name_change(name:str,enable=False):
    if enable:
        name=name.replace("_","xx0xx")
        name=name.replace("\[","xx1xx")
        name=name.replace("\]","xx2xx")

    return name


def write_scl(def_content, scl_path):
    NumRows = 0
    row_items = []

    # Process each line in the def_content
    for line in def_content.split('\n'):
        if line.startswith('ROW'):
            NumRows += 1
            parts = line.split()
            row_item = {}
            row_item["SubrowOrigin"] = int(parts[3])
            row_item["Coordinate"] = int(parts[4])
            row_item["Sitewidth"] = row_item["Sitespacing"] = int(parts[11])
            row_item["NumSites"] = int(parts[7])
            row_item["Siteorient"] = 0 if parts[5] == "FS" else 1
            row_item["Height"] = 2800
            row_item["Sitesymmetry"] = 1
            row_items.append(row_item)
    
    # Generate the output content for the scl file
    with open(scl_path, 'w') as scl_file:
        scl_file.write(f"UCLA scl 1.0\n\nNumRows : {NumRows}\n")
        for row_item in row_items:
            scl_file.write(f"""
CoreRow Horizontal
  Coordinate   : {row_item['Coordinate']}
  Height       : {row_item['Height']}
  Sitewidth    : {row_item['Sitewidth']}
  Sitespacing  : {row_item['Sitespacing']}
  Siteorient   : {row_item['Siteorient']}
  Sitesymmetry : {row_item['Sitesymmetry']}
  SubrowOrigin : {row_item['SubrowOrigin']}  NumSites : {row_item['NumSites']}
End
""")

def remove_blockages_section(input_file, output_file):
    try:
        with open(input_file, 'r') as file:
            lines = file.readlines()
        
        new_lines = []
        in_blockages_section = False
        
        for line in lines:
            if line.strip().startswith("BLOCKAGES"):
                in_blockages_section = True
            elif line.strip() == "END BLOCKAGES":
                in_blockages_section = False
                continue  # Skip the "END BLOCKAGES" line
            
            if not in_blockages_section:
                new_lines.append(line)
        
        with open(output_file, 'w') as file:
            file.writelines(new_lines)
        
        print(f"Processed file saved as {output_file}")
    
    except Exception as e:
        print(f"Error processing file: {e}")

def write_nodes(
    nodes_file: str, block:odb.dbBlock,enable=False
):
    
    fwrite = open(nodes_file, "w", encoding="utf8")
    fwrite.write(
        """\
UCLA nodes 1.0
# Created	:	Jan  6 2005
# User   	:	Gi-Joon Nam & Mehmet Yildiz at IBM Austin Research({gnam, mcan}@us.ibm.com)\n
"""
    )

    insts_set=block.getInsts()
    bterms_set=block.getBTerms()
    macros_set=[inst for inst in insts_set if inst.isBlock()]
    macro_names=[name_change(inst.getName(),enable) for inst in macros_set]

    

    num_terminals=len(bterms_set)+len(macros_set)
    num_nodes=len(insts_set)
    fwrite.write(f"NumNodes : {num_nodes}\n")
    fwrite.write(f"NumTerminals : {num_terminals}\n")

    for inst in insts_set:
        inst:odb.dbInst=inst
        inst_bbox:odb.dbBox=inst.getBBox()
        if not inst.isBlock():
            inst_name=inst.getName()
            inst_size_x=int(inst_bbox.getDX())
            inst_size_y=int(inst_bbox.getDY())
            inst_name=name_change(inst_name,enable)
            fwrite.write(f"\t{inst_name}\t{inst_size_x}\t{inst_size_y}\n")
        else:
            inst_name=inst.getName()
            inst_size_x=int(inst_bbox.getDX())
            inst_size_y=int(inst_bbox.getDY())
            inst_name=name_change(inst_name,enable)
            fwrite.write(f"\t{inst_name}\t{inst_size_x}\t{inst_size_y}\tterminal\n")
    
    


    for bterm in bterms_set:
        bterm:odb.dbBTerm=bterm
        bterm_name=bterm.getName()
        bterm_name=name_change(bterm_name,enable)
        bterm_bbox:odb.Rect=bterm.getBBox()
        bterm_size_x=int(bterm_bbox.dx())
        bterm_size_y=int(bterm_bbox.dy())
        fwrite.write(f"\t{bterm_name}\t{bterm_size_x}\t{bterm_size_y}\tterminal_NI\n")
        

    return macro_names

def write_pl( block:odb.dbBlock, pl_file,enable=False):
        """
        @brief write .pl file
        @param pl_file .pl file
        """
        inst_set=block.getInsts()
        bterms_set=block.getBTerms()
        content = "UCLA pl 1.0\n"
        core_area:odb.Rect=block.getCoreArea()
        # inst1=inst_set[0]
        # inst1:odb.dbInst=inst1
        # inst1_bbox:odb.dbBox=inst1.getBBox()
        # inst1_x=int(inst1_bbox.xMin())
        # inst1_y=int(inst1_bbox.yMin())
        # content += "\n%s %d %d : %s" % (
        #     name_change(inst1.getName()),
        #     inst1_x,
        #     inst1_y,
        #     "N",
        # )  
        for inst in inst_set:
            inst:odb.dbInst=inst
            inst_name=inst.getName()
            inst_name=name_change(inst_name,enable)
            orient=inst.getOrient()
            inst_bbox:odb.dbBox=inst.getBBox()
            inst_x=int(inst_bbox.xMin())
            inst_y=int(inst_bbox.yMin())
            content += "\n%s %d %d : %s" % (
                inst_name,
                inst_x,
                inst_y,
                "N",
            )  

        for bterm in bterms_set:
            bterm:odb.dbBTerm=bterm
            bterm_name=bterm.getName()
            bterm_name=name_change(bterm_name,enable)
            bterm_bbox:odb.dbBox=bterm.getBBox()
            bterm_x=int(bterm_bbox.xMin())
            bterm_y=int(bterm_bbox.yMin())
            content += "\n%s %d %d : %s" % (
                bterm_name,
                bterm_x,
                bterm_y,
                "N",
            )  
        with open(pl_file, "w") as f:
            f.write(content)

def write_nets(net_file, block:odb.dbBlock,enable=False):
    net_set=block.getNets()
    num_pins=0
    for net in net_set:
        net:odb.dbNet=net
        num_pins+=len(net.getITerms())
        num_pins+=len(net.getBTerms())
    num_nets = len(net_set)
    content = """\
UCLA nets 1.0
# Created	:	Dec 27 2004
# User   	:	Gi-Joon Nam & Mehmet Yildiz at IBM Austin Research({gnam, mcan}@us.ibm.com)
"""
    content += "\n"
    content += f"""\
NumNets : {num_nets}
NumPins : {num_pins}
"""
    for id,net in enumerate(net_set):
        net:odb.dbNet=net
        iterms=net.getITerms()
        bterms=net.getBTerms()
        num_pins=len(iterms)+len(bterms)
        net_name=net.getName()
        net_name=name_change(net_name,enable)
        content += f"NetDegree : {num_pins} {net_name}\n"
        for iterm in iterms:
            iterm:odb.dbITerm=iterm
            iterm_io=iterm.getIoType()
            # print(iterm_io)
            if iterm_io == "INPUT":
                direct = 'I'
            else:
                direct = 'O'
            node:odb.dbInst=iterm.getInst()
            node_bbox:odb.dbBox=node.getBBox()
            node_name=node.getName()
            node_name=name_change(node_name,enable)
            iterm_bbox:odb.Rect=iterm.getBBox()
            x_offset=(iterm_bbox.xCenter())-(node_bbox.xMin()+node_bbox.getDX()/2)
            y_offset=(iterm_bbox.yCenter())-(node_bbox.yMin()+node_bbox.getDY()/2)
            content += f"\t{node_name} {direct} : {x_offset} {y_offset}\n"


        for bterm in bterms:
            bterm:odb.dbBTerm=bterm
            bterm_name=bterm.getName()
            bterm_io=bterm.getIoType()
            if bterm_io == "INPUT":
                direct = 'I'
            else:
                direct = 'O'
            bterm_name=name_change(bterm_name,enable)
            content += f"\t{bterm_name} {direct} : 0 0\n"
    # str_node_orient = np.array(placedb.node_orient, dtype=str)
    # for id,net_name in enumerate(placedb.net_names):
    #     net_pin_num = len(placedb.net2pin_map[id])
    #     net_name=str(net_name,'utf-8')
    #     net_name=net_name
    #     net_name=net_name
    #     #print(net_name)
    #     content += f"NetDegree : {net_pin_num} {net_name}\n"
    #     net_pin = placedb.net2pin_map[id]#pin id
    #     # print("net_pin:",net_pin)
    #     net_macro = placedb.pin2node_map[net_pin]#macro id
    #     # print("net_macro:",net_macro)
    #     for i,idmacro in enumerate(net_macro):
    #         pin = net_pin[i]#pin_id
    #         if placedb.pin_direct[pin] == 'OUTPUT':
    #             direct = 'O'
    #         else:
    #             direct = 'I'

    #         node_name=str(placedb.rawdb.nodeName(idmacro))
    #         pin_offset_x=placedb.pin_offset_x[pin]-placedb.node_size_x[idmacro]/2
    #         pin_offset_y=placedb.pin_offset_y[pin]-placedb.node_size_y[idmacro]/2
    #         # if str_node_orient[idmacro] == 'N':
    #         #     pin_offset_x=pin_offset_x
    #         #     pin_offset_y=pin_offset_y
    #         # elif str_node_orient[idmacro] == 'S':
    #         #     pin_offset_x=-pin_offset_x
    #         #     pin_offset_y=-pin_offset_y
    #         # elif str_node_orient[idmacro] == 'FN':
    #         #     pin_offset_x=-pin_offset_x
    #         #     pin_offset_y=pin_offset_y
    #         # elif str_node_orient[idmacro] == 'FS':
    #         #     pin_offset_x=pin_offset_x
    #         #     pin_offset_y=-pin_offset_y
    #         content += f"\t{node_name} {direct} : {pin_offset_x:.6f} {pin_offset_y:.6f}\n"
    with open(net_file, "w", encoding="utf8") as fwrite:
        fwrite.write(content)

def writebookshelf(config_json,bookshelf_dir,benchmark=None,enable=False):
    
    tech=Tech()
    lef_files = config_json["lef_input"]
    def_input = config_json["def_input"]
    for lef_file in lef_files:
        tech.readLef(lef_file)
    design=Design(tech)
    design.evalTclString(f"read_def -continue_on_errors {def_input}")
    # design.readDef(def_input)
    block:odb.dbBlock=design.getBlock()
    if benchmark is None:
        benchmark=block.getName()
    benchdir = f'{bookshelf_dir}/{benchmark}'
    os.makedirs(benchdir,exist_ok=True)
    pl_file = os.path.join(
        benchdir,
        f'{benchmark}.pl'
    )
    nodes_file = os.path.join(
        benchdir,
        f'{benchmark}.nodes'
    )
    nets_file = os.path.join(
        benchdir,
        f'{benchmark}.nets'
    )
    aux_file = os.path.join(
        benchdir,
        f'{benchmark}.aux'
    )

    scl_file = os.path.join(
        benchdir,
        f'{benchmark}.scl'
    )
    grid_file=os.path.join(
        benchdir,
        f"grid.md"

    )

    core_area:odb.Rect=block.getCoreArea()
    x_max = core_area.xMax()
    y_max = core_area.yMax()
    grid_num = 500
    grid_x = (x_max // grid_num) // 10 * 10
    grid_y = (y_max // grid_num) // 10 * 10

    # with open(grid_file,"w") as f:
    #     f.write(f'{{"grid_num":{grid_num},"grid_size":({grid_x},{grid_y})}}')

    

    
    macro_names = write_nodes(nodes_file=nodes_file,block=block,enable=enable)
    print('finish nodes writing')
    with open(f'{benchdir}/{benchmark}.macros', "w") as fwrite:
        fwrite.write("0\n")
        macro_names_str = " ".join(macro_names)
        fwrite.write(f"{macro_names_str}\n")
    write_nets(net_file=nets_file,block=block,enable=enable)
    print('finish net writing')
    write_pl(block=block,pl_file=pl_file,enable=enable)
    print('finish pl writing')
    # os.system(f'cp {def_input} {benchdir}/{benchmark}.def')
    # dest_def=f"{benchdir}/{benchmark}.def"
    # remove_blockages_section(dest_def,dest_def)



    with open(def_input,"r") as f:
        write_scl(f.read(),scl_file)
    print('finish scl writing')

    with open(aux_file,'w') as fwrite:
        fwrite.write(f'RowBasedPlacement :  {benchmark}.nodes  {benchmark}.nets  {benchmark}.pl {benchmark}.scl')
  
if __name__ == "__main__":
    import sys
    config_file=sys.argv[1]
    bookshelf_dir=sys.argv[2]
    if len(sys.argv) > 3:
        benchmark=sys.argv[3]
    else:
        benchmark=None
    
    if len(sys.argv) > 4:
        enable=sys.argv[4]
    else:
        enable=False

    with open(config_file,"r") as f:
        config=json.load(f)

    writebookshelf(config,bookshelf_dir,benchmark,enable)


