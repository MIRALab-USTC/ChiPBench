# Constraints for VGA_ENH_TOP Module

# Define clocks
create_clock -name wb_clk -period 2 [get_ports wb_clk_i]    
create_clock -name pixel_clk -period 2 [get_ports clk_p_i]  
create_clock -name clk_p_o -period 2 [get_ports clk_p_o]    

# Set input delays (relative to respective clocks)
set_input_delay -clock wb_clk 0.5 [get_ports {wbs_adr_i[*] wbs_dat_i[*] wbs_sel_i wbs_we_i wbs_stb_i wbs_cyc_i}]
set_input_delay -clock pixel_clk 0.5 [get_ports rst_i]

# Set output delays (relative to respective clocks)
set_output_delay -clock wb_clk 0.5 [get_ports {wbs_dat_o wb_inta_o wbs_ack_o wbs_rty_o wbs_err_o}]
set_output_delay -clock pixel_clk 0.5 [get_ports {clk_p_o hsync_pad_o vsync_pad_o csync_pad_o blank_pad_o r_pad_o[*] g_pad_o[*] b_pad_o[*]}]

# Specify false paths for asynchronous signals
# set_false_path -from [get_ports rst_i] -to [get_registers *]

# Set max fanout limits (optional)
# set_max_fanout 20 [all_clocks]
