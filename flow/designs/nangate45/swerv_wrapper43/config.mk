export DESIGN_NAME = swerv_wrapper
export DESIGN_NICKNAME = swerv_wrapper43
export PLATFORM    = nangate45

export SYNTH_HIERARCHICAL = 1
#
# RTL_MP Settings
export RTLMP_MAX_INST = 30000
export RTLMP_MIN_INST = 5000
export RTLMP_MAX_MACRO = 12
export RTLMP_MIN_MACRO = 4 

export VERILOG_FILES = $(sort $(wildcard $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/rtl/*.v))
export SDC_FILE      = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/constraint.sdc

export ADDITIONAL_LEFS = $(PLATFORM_DIR)/lef/fakeram45_2048x39.lef \
                         $(PLATFORM_DIR)/lef/fakeram45_256x34.lef \
                         $(PLATFORM_DIR)/lef/fakeram45_64x21.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/rvjtag_tap.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/rvmaskandmatch.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/rvecc_decode.lef 
export ADDITIONAL_LIBS = $(PLATFORM_DIR)/lib/fakeram45_2048x39.lib \
                         $(PLATFORM_DIR)/lib/fakeram45_256x34.lib \
                         $(PLATFORM_DIR)/lib/fakeram45_64x21.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/rvjtag_tap.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/rvmaskandmatch.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/rvecc_decode.lib 

export CORE_UTILIZATION = 40
export PLACE_DENSITY = 0.6
export GPL_TIMING_DRIVEN = 0 


export MACRO_PLACE_HALO    = 10 10
export MACRO_PLACE_CHANNEL = 20 20
export TNS_END_PERCENT     = 100

export FASTROUTE_TCL = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/fastroute.tcl

export GLOBAL_ROUTE_ARGS = -allow_congestion -verbose -congestion_iterations 10

export DETAILED_ROUTE_ARGS = -droute_end_iter 4

