export DESIGN_NICKNAME = bp_be12
export DESIGN_NAME = bp_be_top
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

export ADDITIONAL_LEFS = $(PLATFORM_DIR)/lef/fakeram45_512x64.lef \
                         $(PLATFORM_DIR)/lef/fakeram45_64x32.lef \
                         $(PLATFORM_DIR)/lef/fakeram45_64x96.lef\
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p36.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p539.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p540.lef 
export ADDITIONAL_LIBS = $(PLATFORM_DIR)/lib/fakeram45_512x64.lib \
                         $(PLATFORM_DIR)/lib/fakeram45_64x32.lib \
                         $(PLATFORM_DIR)/lib/fakeram45_64x96.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p36.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p539.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p540.lib 

export CORE_UTILIZATION = 40
export PLACE_DENSITY = 0.8
export GPL_TIMING_DRIVEN = 0



export MACRO_PLACE_HALO = 10 10
export MACRO_PLACE_CHANNEL = 20 20


export TNS_END_PERCENT        = 100

export GLOBAL_ROUTE_ARGS = -allow_congestion -congestion_iterations 1

export DETAILED_ROUTE_ARGS = -droute_end_iter 1