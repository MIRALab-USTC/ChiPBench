export DESIGN_NICKNAME = mor1kx
export DESIGN_NAME = mor1kx
export PLATFORM    = nangate45


export SYNTH_HIERARCHICAL = 1
export VERILOG_FILES = $(sort $(wildcard $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/rtl/*.v))
export SDC_FILE      = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/constraint.sdc

export ADDITIONAL_LEFS = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/spram_8x4.lef \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/spram_8x8.lef \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/spram_8x16.lef \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/spram_9x8.lef \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/spram_9x4.lef \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/spram_12x4.lef \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/spram_12x8.lef 

export ADDITIONAL_LIBS = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/spram_8x4.lib \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/spram_8x8.lib \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/spram_8x16.lib \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/spram_9x8.lib \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/spram_9x4.lib \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/spram_12x4.lib \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/spram_12x8.lib 

# export BLOCKS = memory4 or1200_spram2 or1200_spram3 or1200_spram4 or1200_spram5

export CORE_UTILIZATION = 40
export PLACE_DENSITY = 0.6
export MACRO_PLACE_HALO    = 2 2
export MACRO_PLACE_CHANNEL = 5 5

export DETAILED_ROUTE_ARGS = -droute_end_iter 1
export GLOBAL_ROUTE_ARGS = -allow_congestion -verbose -congestion_iterations 5

export TNS_END_PERCENT  = 100


export SYNTH_MEMORY_MAX_BITS = 1048576
