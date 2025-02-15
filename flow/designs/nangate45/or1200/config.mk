export DESIGN_NICKNAME = or1200
export DESIGN_NAME = or1200_top
export PLATFORM    = nangate45


export SYNTH_HIERARCHICAL = 1
export VERILOG_FILES = $(sort $(wildcard $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/rtl/*.v))
export SDC_FILE      = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/constraint.sdc

export ADDITIONAL_LEFS = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/macro_6x6.lef \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/macro_9x3.lef \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/macro_6x8.lef \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/macro_9x6.lef \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/macro_9x7.lef \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/macro_11x2.lef \
							$(PLATFORM_DIR)/lef/fakeram45_256x16.lef

export ADDITIONAL_LIBS = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/macro_6x6.lib \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/macro_9x3.lib \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/macro_6x8.lib \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/macro_9x6.lib \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/macro_9x7.lib \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/macro_11x2.lib \
							$(PLATFORM_DIR)/lib/fakeram45_256x16.lib


export CORE_UTILIZATION = 40
export PLACE_DENSITY = 0.6


export DETAILED_ROUTE_ARGS = -droute_end_iter 1
export GLOBAL_ROUTE_ARGS = -allow_congestion -verbose -congestion_iterations 5

export TNS_END_PERCENT  = 100


export MACRO_PLACE_HALO    = 2 2
export MACRO_PLACE_CHANNEL = 5 5

export SYNTH_MEMORY_MAX_BITS = 1048576
export MAX_BUFFER_PERCENT = 100