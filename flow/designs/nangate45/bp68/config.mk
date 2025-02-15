export DESIGN_NICKNAME = bp68
export DESIGN_NAME = black_parrot
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

export ABC_AREA = 1


export ADDITIONAL_LEFS = $(PLATFORM_DIR)/lef/fakeram45_512x64.lef \
                         $(PLATFORM_DIR)/lef/fakeram45_256x95.lef \
                         $(PLATFORM_DIR)/lef/fakeram45_64x96.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p26.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p27.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p28.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p30.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p32.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p36.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p38.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p55.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p109_8.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p134_16.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p537.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p539.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p540.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p541.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p542.lef \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lef/bsg_mem_p567.lef
export ADDITIONAL_LIBS = $(PLATFORM_DIR)/lib/fakeram45_512x64.lib \
                         $(PLATFORM_DIR)/lib/fakeram45_256x95.lib \
                         $(PLATFORM_DIR)/lib/fakeram45_64x96.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p26.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p27.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p28.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p30.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p32.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p36.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p38.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p55.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p109_8.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p134_16.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p537.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p539.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p540.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p541.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p542.lib \
                         $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/lib/bsg_mem_p567.lib


export CORE_UTILIZATION = 40
export PLACE_DENSITY = 0.8
export GPL_TIMING_DRIVEN = 0 


export MACRO_PLACE_HALO    = 10 10
export MACRO_PLACE_CHANNEL = 20 20
export TNS_END_PERCENT     = 100

export GLOBAL_ROUTE_ARGS = -allow_congestion -verbose -congestion_iterations 1

export DETAILED_ROUTE_ARGS = -droute_end_iter 1
