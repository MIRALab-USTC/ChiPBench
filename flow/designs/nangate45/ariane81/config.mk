export DESIGN_NAME = ariane
export DESIGN_NICKNAME = ariane81
export PLATFORM    = nangate45

export SYNTH_HIERARCHICAL = 1

# RTL_MP Settings
export RTLMP_MAX_INST = 30000
export RTLMP_MIN_INST = 5000
export RTLMP_MAX_MACRO = 16
export RTLMP_MIN_MACRO = 4

export VERILOG_FILES = $(sort $(wildcard $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/rtl/*.v))
export SDC_FILE      = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/constraint.sdc

export ADDITIONAL_LEFS = $(PLATFORM_DIR)/lef/fakeram45_256x16.lef \
                        $(PLATFORM_DIR)/lef/fakeram45_256x48.lef \
                        $(PLATFORM_DIR)/lef/fakeram45_256x32.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/fifo_v3_1.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/fifo_v3_8.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/ariane_regfile.lef 
export ADDITIONAL_LIBS = $(PLATFORM_DIR)/lib/fakeram45_256x16.lib \
                        $(PLATFORM_DIR)/lib/fakeram45_256x48.lib \
                        $(PLATFORM_DIR)/lib/fakeram45_256x32.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/fifo_v3_1.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/fifo_v3_8.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/ariane_regfile.lib 

export CORE_UTILIZATION = 40
export PLACE_DENSITY = 0.8
export GPL_TIMING_DRIVEN = 0 


export MACRO_PLACE_HALO    = 10 10
export MACRO_PLACE_CHANNEL = 20 20
export TNS_END_PERCENT     = 100
export SKIP_GATE_CLONING   = 1

export GLOBAL_ROUTE_ARGS = -allow_congestion -verbose -congestion_iterations 5

export DETAILED_ROUTE_ARGS = -droute_end_iter 1