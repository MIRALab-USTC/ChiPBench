export DESIGN_NICKNAME = isa_npu
export DESIGN_NAME = npu_top
export PLATFORM    = nangate45


export SYNTH_HIERARCHICAL = 1
export VERILOG_FILES = $(sort $(wildcard $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/rtl/*.v))
export SDC_FILE      = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/constraint.sdc

export ADDITIONAL_LEFS = $(PLATFORM_DIR)/lef/fakeram45_1024x32.lef \
							$(PLATFORM_DIR)/lef/fakeram45_512x64.lef \
							$(PLATFORM_DIR)/lef/fakeram45_256x32.lef \

export ADDITIONAL_LIBS = $(PLATFORM_DIR)/lib/fakeram45_1024x32.lib \
							$(PLATFORM_DIR)/lib/fakeram45_512x64.lib \
							$(PLATFORM_DIR)/lib/fakeram45_256x32.lib \


export CORE_UTILIZATION = 40
export PLACE_DENSITY = 0.8
export GPL_TIMING_DRIVEN = 0


export DETAILED_ROUTE_ARGS = -droute_end_iter 1
export GLOBAL_ROUTE_ARGS = -allow_congestion -verbose -congestion_iterations 5

export TNS_END_PERCENT  = 100


export MACRO_PLACE_HALO    = 2 2
export MACRO_PLACE_CHANNEL = 5 5

export SYNTH_MEMORY_MAX_BITS = 1048576
