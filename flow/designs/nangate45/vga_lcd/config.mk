export DESIGN_NAME = vga_enh_top
export DESIGN_NICKNAME = vga_lcd
export PLATFORM    = nangate45

export VERILOG_FILES = $(sort $(wildcard $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/rtl/*.v))
export SDC_FILE      = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/constraint.sdc
# export SDC_FILE      = /workspace/afix/test/ChiPBench/flow/private/nangate45_macro/vga_lcd/constraint.sdc
export ABC_AREA      = 1


# export ADDITIONAL_LEFS = $(sort $(wildcard $(DESIGN_HOME)/../private/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/*.lib))
# export ADDITIONAL_LIBS = $(sort $(wildcard $(DESIGN_HOME)/../private/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/*.lef))

export ADDITIONAL_LEFS = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/memory_block_128x8.lef \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/memory_block_64x8.lef \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/memory_block_64x24.lef
export ADDITIONAL_LIBS = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/memory_block_128x8.lib \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/memory_block_64x8.lib \
							$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/memory_block_64x24.lib

export SYNTH_HIERARCHICAL = 0
export SYNTH_MEMORY_MAX_BITS = 1048576

export MACRO_PLACE_HALO    = 10 10
export MACRO_PLACE_CHANNEL = 20 20

export CORE_UTILIZATION = 40
export PLACE_DENSITY = 0.6
export TNS_END_PERCENT =100


export GPL_TIMING_DRIVEN=0
export GPL_ROUTABILITY_DRIVEN=0

export RESYNTH_TIMING_RECOVER=0
export REMOVE_ABC_BUFFERS=1

export DETAILED_ROUTE_ARGS = -droute_end_iter 1
export GLOBAL_ROUTE_ARGS = -allow_congestion -verbose -congestion_iterations 5
export MAX_BUFFER_PERCENT = 100