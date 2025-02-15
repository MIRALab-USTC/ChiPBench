# import pickle
import networkx as nx
import numpy as np
# import matplotlib.pyplot as plt







def build_directed_graph(nodes_info, nets):

    G = nx.DiGraph()

    for node_name, node_data in nodes_info.items():
        is_reg_node = node_data["is_register"]
        is_macro_node=node_data["isMacro"]
        is_port_node=node_data["is_port"]
        G.add_node(node_name,isMacro=is_macro_node,is_register=is_reg_node,is_port=is_port_node)


    for net in nets:
        if net["output"] is None:
            continue
        out_node= net["output"]  
        for in_node in net["inputs"]:
            G.add_edge(out_node, in_node, internal_edge=False, weight=0)
    
    return G

def search_pathsM2C(G,start_node,max_depth=100):
    paths = []

    def dfs(current_node, path, depth):
        # Stop searching if exceeding maximum depth
        if depth > max_depth:
            return
        
        # Add current node to path
        path.append(current_node)

        # Check if termination condition is met: isMacro=True and pin_type='input'
        if (G.nodes[current_node].get('is_register', False) ) and depth>0:
            # Record current complete path and stop searching further
            paths.append(path.copy())
            path.pop()
            return
        
        # Continue searching forward
        for neighbor in G.successors(current_node):
            # Avoid cycles
            if neighbor not in path:
                dfs(neighbor, path, depth + 1)

        # Backtrack
        path.pop()
    # Start DFS
    dfs(start_node, [], 0)
    return paths

def search_paths_to_macro_no_memo(G, start_node, max_depth=100):
    """
    Perform DFS search from start_node within max_depth range,
    collect all simple paths reaching nodes with (isMacro=True, pin_type='input') (without memoization).
    
    Parameters:
      G (nx.DiGraph): Directed graph
      start_node:     Starting node
      max_depth (int) Maximum search depth

    Returns:
      List[List]: All simple paths that meet the termination condition (isMacro=True, pin_type='input')
    """
    paths = []

    def dfs(current_node, path, depth):
        # Stop searching if exceeding maximum depth
        if depth > max_depth:
            return
        
        # Add current node to path
        path.append(current_node)

        # Check if termination condition is met: isMacro=True and pin_type='input'
        if (G.nodes[current_node].get('isMacro', False) or G.nodes[current_node].get('is_port', False)) and depth>0:
            # Record current complete path and stop searching further
            paths.append(path.copy())
            path.pop()
            return
        
        # Continue searching forward
        for neighbor in G.successors(current_node):
            # Avoid cycles
            if neighbor not in path:
                dfs(neighbor, path, depth + 1)

        # Backtrack
        path.pop()

    # Start DFS
    dfs(start_node, [], 0)
    return paths




def getDataFlow_main(G, macro_names,depth=10):
    """
    Analyze path information between macro units
    
    Parameters:
        G: networkx graph object
        macro_names: list of macro unit names
        
    Returns:
        macro_paths_num_array: matrix of path counts between macro units
        macro_paths_data_flow_array: data flow matrix between macro units
    """
    num_macro = len(macro_names)
    
    macro_name_to_index = {}
    for i, macro_name in enumerate(macro_names):
        macro_name_to_index[macro_name] = i

    path_num_array = np.zeros((len(macro_names), len(macro_names)))
    path_length_array = np.zeros((len(macro_names), len(macro_names)))
    path_data_flow_array = np.zeros((len(macro_names), len(macro_names)))

    for i, macro_name in enumerate(macro_names):
        paths = search_paths_to_macro_no_memo(G, macro_name, depth)
        for j, path in enumerate(paths):
            end_node = path[-1]
            end_node_index = macro_name_to_index[end_node]
            path_num_array[i, end_node_index] += 1
            reg_count = sum(1 for node in path if G.nodes[node].get('is_register', False))
            path_length_array[i, end_node_index] += reg_count

            data_flow_count = 0.5**reg_count
            path_data_flow_array[i, end_node_index] += data_flow_count
        print(f"{macro_name} has {len(paths)} paths")

    macro_paths_num_array = np.zeros((num_macro, num_macro), dtype=int)
    macro_paths_data_flow_array = np.zeros((num_macro, num_macro), dtype=float)
    
    for i in range(num_macro):
        for j in range(i+1, num_macro):
            if path_num_array[i,j]+path_num_array[j,i] > 0:
                macro_paths_num_array[i,j] = macro_paths_num_array[j,i] = path_num_array[i,j] + path_num_array[j,i]
                macro_paths_data_flow_array[i,j] = macro_paths_data_flow_array[j,i] = path_data_flow_array[i,j] + path_data_flow_array[j,i]
                print(f"{macro_names[i]} to {macro_names[j]}: {macro_paths_num_array[i,j]}, data_flow: {macro_paths_data_flow_array[i,j]}")
                
    return macro_paths_num_array, macro_paths_data_flow_array

# if __name__ == "__main__":

#     # tech = Tech()

#     # design = Design(tech)

#     # db_path="/workspace/afix/test/ChiPBench/flow/results/nangate45/bp_fe/bbo/2_3_floorplan_macro.odb"
#     # design.readDb(db_path)

#     # block:odb.dbBlock=design.getBlock()

#     # # G=create_graph(block)
#     # # with open("G.pkl","rb") as f:
#     # #     G=pickle.load(f)
#     # # with open("G.pkl","wb") as f:
#     # #     pickle.dump(G,f)

#     # inst_set=block.getInsts()

#     # macor_set=[inst for inst in inst_set if inst.isBlock()]

#     # macro_names=[macro.getName() for macro in macor_set]


#     # with open("macro_names.pkl","wb") as f:
#     #     pickle.dump(macro_names,f)

#     # # macro_1:odb.dbInst=macor_set[0]

#     # # with open("macro_1.pkl","wb") as f:
#     # #     pickle.dump(macro_1.getName(),f)
#     # # macro_2:odb.dbInst=macor_set[1]
#     # sys.exit()



#     with open("G.pkl","rb") as f:
#         G=pickle.load(f)


#     with open("macro_names.pkl","rb") as f:
#         macro_names=pickle.load(f)

#     print("node_num:",G.number_of_nodes())
#     print("edge_num:",G.number_of_edges())

#     depth_list=[i for i in range(8,15,1)]
#     macro_paths_num_array_list=[]
#     macro_paths_data_flow_array_list=[]
#     for depth in depth_list:
#         macro_paths_num_array, macro_paths_data_flow_array=getDataFlow_main(G,macro_names,depth=depth)
#         normalized_data_flow = macro_paths_data_flow_array / np.sum(macro_paths_data_flow_array)*2
#         macro_paths_data_flow_array_list.append(normalized_data_flow)
    
#     # Create subplot grid
#     n_plots = len(macro_paths_data_flow_array_list)
#     n_cols = 4
#     n_rows = (n_plots + n_cols - 1) // n_cols
    
#     fig, axes = plt.subplots(n_rows, n_cols, figsize=(20, 5*n_rows))
#     axes = axes.flatten()
    
#     # Plot heatmap for each depth
#     for idx, (depth, data_flow) in enumerate(zip(depth_list, macro_paths_data_flow_array_list)):
#         im = axes[idx].imshow(data_flow, cmap='jet', vmin=0, vmax=1)
#         axes[idx].set_title(f'Depth = {depth}')
#         plt.colorbar(im, ax=axes[idx])
        
#         # Set axis labels
#         axes[idx].set_xlabel('Macro Index')
#         axes[idx].set_ylabel('Macro Index')
    
#     # Remove extra subplots
#     for idx in range(len(macro_paths_data_flow_array_list), len(axes)):
#         fig.delaxes(axes[idx])
    
#     plt.tight_layout()
#     plt.savefig('data_flow_heatmaps.png')
#     plt.close()

