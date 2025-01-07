import os
import sys
import time
import shutil
import numpy as np
import logging
import Params
import PlaceDB

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

def findmacroid(placedb:PlaceDB.PlaceDB):
    node_size_y_mean = placedb.node_size_y.mean()
    macroid = np.where(placedb.node_size_y > 10*node_size_y_mean)[0]

    # macroid=list(range(
    #        placedb.num_movable_nodes + placedb.num_terminals,
    #        placedb.num_movable_nodes + placedb.num_terminals + placedb.num_terminal_NIs,
    #     ))
    return macroid

def write_nodes(
    nodes_file: str, placedb: PlaceDB.PlaceDB
):
    
    fwrite = open(nodes_file, "w", encoding="utf8")
    fwrite.write(
        """\
UCLA nodes 1.0
# Created	:	Jan  6 2005
# User   	:	Gi-Joon Nam & Mehmet Yildiz at IBM Austin Research({gnam, mcan}@us.ibm.com)\n
"""
    )
    
    macro_id = findmacroid(placedb)

    macro_names = {}
    num_macros = len(macro_id)
    num_terminals=placedb.num_terminals + placedb.num_terminal_NIs
    fwrite.write(f"NumNodes : {placedb.num_physical_nodes}\n")
    fwrite.write(f"NumTerminals : {num_terminals}\n")
    
    
    for i in range(placedb.num_movable_nodes):
        width = int(placedb.node_size_x[i])
        height = int(placedb.node_size_y[i])
        name=str(placedb.rawdb.nodeName(i))
        #name=str(placedb.rawdb.nodeName(i))
        fwrite.write(f"\t{name}\t{int(width)}\t{int(height)}\n")
    fixed_node_indices = list(placedb.rawdb.fixedNodeIndices())
    for i in fixed_node_indices:
        width = int(placedb.node_size_x[i])
        height = int(placedb.node_size_y[i])
        name=str(placedb.rawdb.nodeName(i))
        fwrite.write(f"\t{name}\t{width}\t{height}\tterminal\n")
        
        name_macro=str(placedb.node_names[i][:-len(b'.DREAMPlace.Shape0')].decode('utf-8'))
        macro_names[name_macro] = i
        
    for i in range(
        placedb.num_movable_nodes + placedb.num_terminals,
        placedb.num_movable_nodes + placedb.num_terminals + placedb.num_terminal_NIs,
    ):
        width = int(placedb.node_size_x[i])
        height = int(placedb.node_size_y[i])
        name=str(placedb.rawdb.nodeName(i))
        fwrite.write(f"\t{name}\t{width}\t{height}\tterminal_NI\n")
        #macro_names[placedb.node_names[i][:-len(b'.DREAMPlace.Shape0')]] = i

    fwrite.close()
    #print(macro_names)
    return macro_names

def write_pl( placedb: PlaceDB.PlaceDB, pl_file):
        """
        @brief write .pl file
        @param pl_file .pl file
        """
        content = "UCLA pl 1.0\n"
        str_node_names = np.array(placedb.node_names, dtype=str)
        str_node_orient = np.array(placedb.node_orient, dtype=str)
        str_node_orient = ["N" if orient == "UNKNOWN" else orient for orient in str_node_orient]
        node_x = placedb.node_x
        node_y = placedb.node_y
        for i in range(placedb.num_movable_nodes):
            content += "\n%s %d %d : %s" % (
                str_node_names[i],
                node_x[i],
                node_y[i],
                str_node_orient[i],
            )  
         # use the original fixed cells, because they are expanded if they contain shapes
        fixed_node_indices = list(placedb.rawdb.fixedNodeIndices())
        for i, node_id in enumerate(fixed_node_indices):
            content += "\n%s %d %d : %s /FIXED" % (
                str(placedb.rawdb.nodeName(node_id)),
                
                float(node_x[node_id]),
                float(node_y[node_id]),
                "N",  # still hard-coded
            )
        for i in range(
           placedb.num_movable_nodes + placedb.num_terminals,
           placedb.num_movable_nodes + placedb.num_terminals + placedb.num_terminal_NIs,
        ):
            content += "\n%s %d %d : %s /FIXED_NI" % (
                str_node_names[i],
                node_x[i],
                node_y[i],
                str_node_orient[i],
            )
        with open(pl_file, "w") as f:
            f.write(content)

def write_nets(net_file, placedb: PlaceDB.PlaceDB):
    num_nets = len(placedb.net2pin_map)
    num_pins = len(placedb.pin2net_map)
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
    for id,net_name in enumerate(placedb.net_names):
        net_pin_num = len(placedb.net2pin_map[id])
        net_name=str(net_name,'utf-8')
        net_name=net_name
        net_name=net_name
        #print(net_name)
        content += f"NetDegree : {net_pin_num} {net_name}\n"
        net_pin = placedb.net2pin_map[id]#pin id
        net_macro = placedb.pin2node_map[net_pin]#macro id
        for i,idmacro in enumerate(net_macro):
            pin = net_pin[i]#pin_id
            if placedb.pin_direct[pin] == 'OUTPUT':
                direct = 'O'
            else:
                direct = 'I'

            node_name=str(placedb.rawdb.nodeName(idmacro))
            pin_offset_x=placedb.pin_offset_x[pin]-placedb.node_size_x[idmacro]/2
            pin_offset_y=placedb.pin_offset_y[pin]-placedb.node_size_y[idmacro]/2
            content += f"\t{node_name} {direct} : {pin_offset_x:.6f} {pin_offset_y:.6f}\n"
    with open(net_file, "w", encoding="utf8") as fwrite:
        fwrite.write(content)

def writebookshelf(placedb: PlaceDB.PlaceDB, params: Params.Params):
    benchmark = params.design_name
    benchdir = f'./benchmarks/{benchmark}'
    if not os.path.exists(benchdir):
        os.makedirs(benchdir)
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
    
    macro_names = write_nodes(nodes_file=nodes_file,placedb=placedb)
    print('finish nodes writing')
    with open(f'benchmarks/{params.design_name}/{benchmark}.macros', "w") as fwrite:
        fwrite.write("0\n")
        macro_name_list=macro_names.keys()
        macro_names_str = " ".join(macro_name_list)
        fwrite.write(f"{macro_names_str}\n")
    write_nets(net_file=nets_file,placedb=placedb)
    print('finish net writing')
    write_pl(placedb=placedb,pl_file=pl_file)
    print('finish pl writing')



    with open(params.def_input,"r") as f:
        write_scl(f.read(),scl_file)
    print('finish scl writing')

    with open(aux_file,'w') as fwrite:
        fwrite.write(f'RowBasedPlacement :  {benchmark}.nodes  {benchmark}.nets  {benchmark}.pl {benchmark}.scl')
  
if __name__ == "__main__":
    logging.root.name = 'DREAMPlace'
    logging.basicConfig(level=logging.INFO,
                        format='[%(levelname)-7s] %(name)s - %(message)s',
                        stream=sys.stdout)
    params = Params.Params()
    params.printWelcome()
    if len(sys.argv) == 1 or '-h' in sys.argv[1:] or '--help' in sys.argv[1:]:
        params.load('test/ariane133.json')
    elif len(sys.argv) != 2:
        logging.error("One input parameters in json format in required")
        params.printHelp()
        exit()
    else:
        params.load(sys.argv[1])
    
    
    params.design_name,_=os.path.splitext(os.path.basename(sys.argv[1]))
    

    remove_blockages_section(params.def_input,params.def_input)

    logging.info("parameters = %s" % (params))
    os.environ["OMP_NUM_THREADS"] = "%d" % (params.num_threads)
    tt = time.time()
    placedb = PlaceDB.PlaceDB()
    placedb.read(params)
    logging.info("reading database takes %.2f seconds" % (time.time() - tt))
    writebookshelf(placedb,params)


