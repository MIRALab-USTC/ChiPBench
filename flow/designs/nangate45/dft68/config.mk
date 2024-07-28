export DESIGN_NICKNAME = dft68
export DESIGN_NAME = dft_top
export PLATFORM    = nangate45


export VERILOG_FILES =$(sort $(wildcard ./designs/$(PLATFORM)/$(DESIGN_NICKNAME)/rtl/*.v))

export SDC_FILE      =./designs/$(PLATFORM)/$(DESIGN_NICKNAME)/constraint.sdc

export ABC_AREA      = 1

export ADDITIONAL_LEFS = $(sort $(wildcard ./designs/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/*.lef))
export ADDITIONAL_LIBS = $(sort $(wildcard ./designs/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/*.lib))

export CORE_UTILIZATION = 40
export PLACE_DENSITY = 0.6
export TNS_END_PERCENT =100

export SYNTH_HIERARCHICAL = 1

export MACRO_PLACE_HALO    = 5 5
export MACRO_PLACE_CHANNEL = 10 10

# export RTLMP_MAX_INST = 30000
# export RTLMP_MIN_INST = 5000
# export RTLMP_MAX_MACRO = 30
# export RTLMP_MIN_MACRO = 10
export GLOBAL_ROUTE_ARGS = -allow_congestion -verbose -congestion_iterations 5

export DETAILED_ROUTE_ARGS = -droute_end_iter 4




