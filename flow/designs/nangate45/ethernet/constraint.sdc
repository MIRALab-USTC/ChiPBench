# eth_top.sdc - Simple SDC file for eth_top module

# Define clocks
create_clock -name wb_clk -period 1.0 [get_ports wb_clk_i]
create_clock -name mtx_clk -period 1.0 [get_ports mtx_clk_pad_i]
create_clock -name mrx_clk -period 1.0 [get_ports mrx_clk_pad_i]

# Input delay constraints
set_input_delay -clock [get_clocks wb_clk] 0.2 [get_ports wb_dat_i]
set_input_delay -clock [get_clocks wb_clk] 0.2 [get_ports wb_adr_i]
set_input_delay -clock [get_clocks wb_clk] 0.2 [get_ports wb_sel_i]
set_input_delay -clock [get_clocks wb_clk] 0.2 [get_ports wb_we_i]
set_input_delay -clock [get_clocks wb_clk] 0.2 [get_ports wb_cyc_i]
set_input_delay -clock [get_clocks wb_clk] 0.2 [get_ports wb_stb_i]
set_input_delay -clock [get_clocks mrx_clk] 0.2 [get_ports mrxd_pad_i]
set_input_delay -clock [get_clocks mrx_clk] 0.2 [get_ports mrxdv_pad_i]

# Output delay constraints
set_output_delay -clock [get_clocks wb_clk] 0.2 [get_ports wb_dat_o]
set_output_delay -clock [get_clocks wb_clk] 0.2 [get_ports wb_ack_o]
set_output_delay -clock [get_clocks wb_clk] 0.2 [get_ports wb_err_o]
set_output_delay -clock [get_clocks wb_clk] 0.2 [get_ports m_wb_adr_o]
set_output_delay -clock [get_clocks wb_clk] 0.2 [get_ports m_wb_dat_o]
set_output_delay -clock [get_clocks wb_clk] 0.2 [get_ports mtxd_pad_o]
set_output_delay -clock [get_clocks wb_clk] 0.2 [get_ports mtxen_pad_o]

# set_false_path -from [get_ports wb_rst_i]
# set_multicycle_path 2 -setup -to [get_ports wb_dat_o]
# set_multicycle_path 1 -hold  -to [get_ports wb_dat_o]

# Input constraints for asynchronous control signals
set_input_delay 0 [get_ports wb_rst_i]
set_input_delay 0 [get_ports int_o]


