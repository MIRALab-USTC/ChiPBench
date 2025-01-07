source $::env(SCRIPTS_DIR)/load.tcl
erase_non_stage_variables floorplan

load_design 2_3_floorplan_macro.odb 2_1_floorplan.sdc


lassign $::env(MACRO_PLACE_HALO) halo_x halo_y
lassign $::env(MACRO_PLACE_CHANNEL) channel_x channel_y
set halo_max [expr max($halo_x, $halo_y)]
set channel_max [expr max($channel_x, $channel_y)]
set blockage_width [expr max($halo_max, $channel_max/2)]

source $::env(SCRIPTS_DIR)/placement_blockages.tcl
block_channels $blockage_width 

write_db $::env(RESULTS_DIR)/2_3_floorplan_macro.odb