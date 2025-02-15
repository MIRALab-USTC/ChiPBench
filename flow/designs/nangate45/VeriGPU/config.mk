export DESIGN_NICKNAME = VeriGPU
export DESIGN_NAME = gpu_card
export PLATFORM    = nangate45


export SYNTH_HIERARCHICAL = 1
export VERILOG_FILES = $(sort $(wildcard $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/rtl/*.sv))
export SDC_FILE      = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/constraint.sdc

export ADDITIONAL_LEFS = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/core.lef \
						$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/small_mem.lef 

export ADDITIONAL_LIBS = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/core.lib \
						$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/small_mem.lib 
# export BLOCKS = memory4 or1200_spram2 or1200_spram3 or1200_spram4 or1200_spram5

export CORE_UTILIZATION = 40
export PLACE_DENSITY = 0.6
# export MACRO_PLACE_HALO    = 2 2
# export MACRO_PLACE_CHANNEL = 5 5

export DETAILED_ROUTE_ARGS = -droute_end_iter 1
export GLOBAL_ROUTE_ARGS = -allow_congestion -verbose -congestion_iterations 5

export TNS_END_PERCENT  = 0

export MACRO_PLACE_HALO    = 5 5
export MACRO_PLACE_CHANNEL = 10 10
export SYNTH_MEMORY_MAX_BITS = 1048576

export REMOVE_ABC_BUFFERS = 1
export MAX_BUFFER_PERCENT = 100
