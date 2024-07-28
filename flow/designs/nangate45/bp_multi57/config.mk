export DESIGN_NICKNAME = bp_multi57
export DESIGN_NAME = bp_multi_top
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
export ABC_AREA      = 1

export ADDITIONAL_LEFS = $(PLATFORM_DIR)/lef/fakeram45_512x64.lef \
                         $(PLATFORM_DIR)/lef/fakeram45_256x96.lef \
                         $(PLATFORM_DIR)/lef/fakeram45_32x64.lef \
                         $(PLATFORM_DIR)/lef/fakeram45_64x96.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p26.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p28.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p30.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p38.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p58.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p97.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p99.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p109.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p131.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p134.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p136.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p537.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p542.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p570.lef 
export ADDITIONAL_LIBS = $(PLATFORM_DIR)/lib/fakeram45_512x64.lib \
                         $(PLATFORM_DIR)/lib/fakeram45_256x96.lib \
                         $(PLATFORM_DIR)/lib/fakeram45_32x64.lib \
                         $(PLATFORM_DIR)/lib/fakeram45_64x96.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p26.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p28.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p30.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p38.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p58.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p97.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p99.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p109.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p131.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p134.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p136.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p537.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p542.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p570.lib 


export DIE_AREA    = 0 0 1100 1100 
export CORE_AREA   = 10.07 9.8 1090 1090
export PLACE_PINS_ARGS = -exclude left:100-1100 -exclude right:100-1100 -exclude top:*

export MACRO_PLACE_HALO = 10 10
export MACRO_PLACE_CHANNEL = 20 20

export PLACE_DENSITY_LB_ADDON = 0.05
export SKIP_GATE_CLONING      = 1


export GLOBAL_ROUTE_ARGS = -allow_congestion -verbose -congestion_iterations 1

export DETAILED_ROUTE_ARGS = -droute_end_iter 1