################################################################
##                                                            ##
## 1ST TRY TO CREATE A PERSONAL AND MODULAR MAKEFILE AS A PRO ##
##                                                            ##
################################################################

## this make file is a Dispatcher of "sub"-makefile

#########################
## working area set up ##
#########################

WORK_DIR := work
RTL_DIR  := rtl
SIM_DIR  := bench
TCL_DIR  := scripts
DOC_DIR  := doc

## non-tcl scripts
BIN_DIR  := bin

## flows-specific dir
IPS_DIR  := cores
XDC_DIR  := xdc

TEST_DIR := test
TEMP_DIR := temp
LOG_DIR  := log


###########################################
## define TOP MODULE and verilog sources ##
###########################################

##---TEST: I2S_RX---##
### rtl and sim top modules ( module's name e.g gates and tb_gates)
#RTL_TOP_MODULE   := I2S_RX
#SIM_TOP_MODULE   := tb_I2S_RX
### rtl and simulation sources (file.v e tb_file.v etc)
#RTL_VLOG_SOURCES := $(RTL_DIR)/I2S_RX.v
#SIM_VLOG_SOURCES := $(SIM_DIR)/tb_I2S_RX.v

##---TEST: I2S_TX---##
### rtl and sim top modules ( module's name e.g gates and tb_gates)
#RTL_TOP_MODULE   := I2S_TX
#SIM_TOP_MODULE   := tb_I2S_TX
### rtl and simulation sources (file.v e tb_file.v etc)
#RTL_VLOG_SOURCES := $(RTL_DIR)/I2S_TX.v
#SIM_VLOG_SOURCES := $(SIM_DIR)/tb_I2S_TX.v

###---TEST: PassTrough---##
### rtl and sim top modules ( module's name e.g gates and tb_gates)
#RTL_TOP_MODULE   := hw_PassTrough
#SIM_TOP_MODULE   := tb_PassTrough
### rtl and simulation sources (file.v e tb_file.v etc)
#RTL_VLOG_SOURCES := $(RTL_DIR)/I2S_RX.v $(RTL_DIR)/I2S_TX.v $(RTL_DIR)\lrck_gen.v $(RTL_DIR)/Debouncer.v $(RTL_DIR)/hw_PassTrough.v
#SIM_VLOG_SOURCES := $(SIM_DIR)/tb_PassTrough.v

##---TEST: I2S_TX---##
### rtl and sim top modules ( module's name e.g gates and tb_gates)
#RTL_TOP_MODULE   := I2S_TX
#SIM_TOP_MODULE   := tb_I2S_TX
### rtl and simulation sources (file.v e tb_file.v etc)
#RTL_VLOG_SOURCES := $(RTL_DIR)/I2S_TX.v
#SIM_VLOG_SOURCES := $(SIM_DIR)/tb_I2S_TX.v

###---Test:VolumeModulator---##
### rtl and sim top modules ( module's name e.g gates and tb_gates)
#RTL_TOP_MODULE   := VolumeModulator
#SIM_TOP_MODULE   := tb_VolumeModulator1
### rtl and simulation sources (file.v e tb_file.v etc)
#RTL_VLOG_SOURCES := $(RTL_DIR)/VolumeModulator.v
#SIM_VLOG_SOURCES := $(SIM_DIR)/tb_VolumeModulator1.v

###---Test:BitCrusher---##
### rtl and sim top modules ( module's name e.g gates and tb_gates)
#RTL_TOP_MODULE   := BitCrusher
#SIM_TOP_MODULE   := tb_BitCrusher
### rtl and simulation sources (file.v e tb_file.v etc)
#RTL_VLOG_SOURCES := $(RTL_DIR)/BitCrusher.v
#SIM_VLOG_SOURCES := $(SIM_DIR)/tb_BitCrusher.v

###---Test:NoiseGate---##
### rtl and sim top modules ( module's name e.g gates and tb_gates)
#RTL_TOP_MODULE   := NoiseGate
#SIM_TOP_MODULE   := tb_NoiseGate
### rtl and simulation sources (file.v e tb_file.v etc)
#RTL_VLOG_SOURCES := $(RTL_DIR)/NoiseGate.v
#SIM_VLOG_SOURCES := $(SIM_DIR)/tb_NoiseGate.v


###---TEST: DownSampler---##
### rtl and sim top modules ( module's name e.g gates and tb_gates)
#RTL_TOP_MODULE   := DownSampler
#SIM_TOP_MODULE   := tb_DownSampler
### rtl and simulation sources (file.v e tb_file.v etc)
#RTL_VLOG_SOURCES := $(RTL_DIR)/DownSampler.v
#SIM_VLOG_SOURCES := $(SIM_DIR)/tb_DownSampler.v

##---TEST: GENERAL---##
## rtl and sim top modules ( module's name e.g gates and tb_gates)
RTL_TOP_MODULE   := AUDIO
SIM_TOP_MODULE   := tb_VolumeModulator1
## rtl and simulation sources (file.v e tb_file.v etc)
RTL_VLOG_SOURCES := $(RTL_DIR)/AUDIO.v $(RTL_DIR)/I2S_RX.v $(RTL_DIR)/DSP_AUDIO.v $(RTL_DIR)/FIR_LP_31tap.v $(RTL_DIR)/NoiseGate.v $(RTL_DIR)/BitCrusher.v $(RTL_DIR)/DownSampler.v $(RTL_DIR)/VolumeModulator.v $(RTL_DIR)/I2S_TX.v $(RTL_DIR)\lrck_gen.v $(RTL_DIR)/Debouncer.v
SIM_VLOG_SOURCES := $(SIM_DIR)/tb_VolumeModulator1.v


#######################
## IPS sources setup ##
#######################

## this assume to simulate the IPs whith the pregenerate netlist

ifneq ($(wildcard $(IPS_DIR)/*/*sim_netlist.v ),)
   IPS_SOURCES += $(wildcard $(IPS_DIR)/*/*sim_netlist.v )
endif

## gruop all sources (rtl'n'sim)
VLOG_SOURCES     := $(RTL_VLOG_SOURCES) $(SIM_VLOG_SOURCES) $(IPS_SOURCES)

##______________________________________________________________________________________________________________________________

###############################################
## Target FPGA devices and external memories ##
###############################################

board := ArtyZ7

## default: Artix7 on Digilent Aty/Arty A7 development boards
part  := xc7z020clg400-1

## default: 128 MB Quad SPI Flash on Digilent Arty/Arty A7 development boards (but different chip IDs between Arty And Arty A7)
ifeq ($(board),Arty)
   flash := mt25ql128-spi-x1_x2_x4
else
ifeq ($(board),ArtyZ7)
   flash := s25fl128s-3.3v-qspi-x2-single
else
   $(error ERROR: Unknown board name $(board))
endif
endif

##______________________________________________________________________________________________________________________________

###############################
## Vivado check and settings ##
###############################


## installation check
ifeq ($(shell which vivado 2> /dev/null),)
   @$(error ERROR: No 'vivado' executable found in search path! CHECK VIVADO INSTALLATION...force un exit....)
endif



## Default vivado mode

#mode ?= batch
#mode ?= gui
mode ?= tcl

##_____________________________________________________________________________________________________________________________

###################
## LINUX alieses ##
###################

ECHO  := echo -e
RM    := rm -f -v
RMDIR := rm -rf -v
MKDIR := mkdir -p -v

##_____________________________________________________________________________________________________________________________

##############################################
##   export variables to tclsh and Vivado   ##
##############################################

## export target device and memory IDs to implementation flows
export XILINX_DEVICE=$(part)
export QFLASH_MEMORY=$(flash)
## export the chosen working directory to all flows
export WORK_DIR
## export HDL variables to xvlog/xvhdl/xelab flows
export RTL_TOP_MODULE
export SIM_TOP_MODULE

ifneq ($(strip $(RTL_VLOG_SOURCES)),)
   export RTL_VLOG_SOURCES
endif

ifneq ($(strip $(SIM_VLOG_SOURCES)),)
   export SIM_VLOG_SOURCES
endif

ifneq ($(strip $(VLOG_SOURCES)),)
   export VLOG_SOURCES
endif

ifneq ($(strip $(VLOG_DEFINES)),)
   export VLOG_DEFINES
endif

ifneq ($(strip $(IPS_SOURCES)),)
   export IPS_SOURCES
endif

#####______________________________________________________________________________________________________________________________


#################
## extra flags ##
#################

## 'make' extra flags
MAKEFLAGS += --warn-undefined-variables --debug

## Bash configuration (be picky and exit immediately on any error)
SHELL := bash
.SHELLFLAGS := -e -u -o pipefail -c

## default target
.DEFAULT_GOAL := help

.PHONY : default
default : help


#####___________________________________________________________________________________________________________________________


##############################
## create the working area: ##
##############################

.PHONY : area
area : ## set up the working area
	@$(MKDIR) $(RTL_DIR)
	@$(MKDIR) $(SIM_DIR)

	@$(MKDIR) $(TCL_DIR)/common
	@$(MKDIR) $(TCL_DIR)/sim
	@$(MKDIR) $(TCL_DIR)/build
	@$(MKDIR) $(TCL_DIR)/install
	@$(MKDIR) $(TCL_DIR)/debug

	@$(MKDIR) $(BIN_DIR)

	@$(MKDIR) $(DOC_DIR)
	@$(MKDIR) $(IPS_DIR)
	@$(MKDIR) $(XDC_DIR)

	@$(MKDIR) $(WORK_DIR)/sim
	@$(MKDIR) $(WORK_DIR)/sim/log
	@$(MKDIR) $(WORK_DIR)/sim/tmp
	@$(MKDIR) $(WORK_DIR)/sim/test
	@$(MKDIR) $(WORK_DIR)/sim/vcd
	@$(MKDIR) $(WORK_DIR)/sim/wdb

	@$(MKDIR) $(WORK_DIR)/build
	@$(MKDIR) $(WORK_DIR)/build/log
	@$(MKDIR) $(WORK_DIR)/build/tmp
	@$(MKDIR) $(WORK_DIR)/build/test
	@$(MKDIR) $(WORK_DIR)/build/outputs
	@$(MKDIR) $(WORK_DIR)/build/reports

	@$(MKDIR) $(TEMP_DIR)
	@$(MKDIR) $(TEST_DIR)

	@$(ECHO) "\n   -- Working area setup completed !\n\n"
	@$(ECHO) "\n   --copy all scripts (.tcl and makefil.*) from dir /std_dir/scripts !!!\n\n"

#######_________________________________________________________________________________________________________________________


#################################
## TARGET IMPLEMENTATION FILES ##
#################################

## include sub-makefiles for modular MAKEFILE

## simulation targets
ifneq ($(wildcard $(TCL_DIR)),)
   -include $(TCL_DIR)/sim/Makefile.sim
endif
## implementation targets
ifneq ($(wildcard $(TCL_DIR)),)
   -include $(TCL_DIR)/build/Makefile.build
endif
## programming targets
ifneq ($(wildcard $(TCL_DIR)),)
   -include $(TCL_DIR)/install/Makefile.install
endif
#####______________________________________________________________________________________________________________________________


##########################
## Default terget  HELP ##
##########################

MAKEFILE_SIM     := $(TCL_DIR)/sim/Makefile.sim
MAKEFILE_BUILD   := $(TCL_DIR)/build/Makefile.build
MAKEFILE_INSTALL := $(TCL_DIR)/install/Makefile.install

.PHONY : help
help:

	@$(ECHO) "\nUsage: make <target> [mode=gui|tcl|batch] [variables]"

	@$(ECHO) "\nGeneral targets:\n"
	@grep -E '^[a-zA-Z_-|/]+ :.*?## .*$$' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "- make \033[36m%-18s\033[0m %s\n", $$1, $$2}'

	@$(ECHO) "\nSimulation targets:\n"
	@grep -E '^[a-zA-Z_-|/]+ :.*?## .*$$' $(MAKEFILE_SIM) | awk 'BEGIN {FS = ":.*?## "}; {printf "- make \033[36m%-18s\033[0m %s\n", $$1, $$2}'
	
	@$(ECHO) "\nImplementation targets:\n"
	@grep -E '^[a-zA-Z_-|/]+ :.*?## .*$$' $(MAKEFILE_BUILD) | awk 'BEGIN {FS = ":.*?## "}; {printf "- make \033[36m%-18s\033[0m %s\n", $$1, $$2}'

	@$(ECHO) "\nProgramming targets:\n"
	@grep -E '^[a-zA-Z_-|/]+ :.*?## .*$$' $(MAKEFILE_INSTALL) | awk 'BEGIN {FS = ":.*?## "}; {printf "- make \033[36m%-18s\033[0m %s\n", $$1, $$2}'

	@$(ECHO) ""
	@$(ECHO) "Target Xilinx device:            $(XILINX_DEVICE)"
	@$(ECHO) "External Quad SPI Flash memory:  $(QFLASH_MEMORY)"
	@$(ECHO) ""

	@$(ECHO) "\nExamples:"
	@$(ECHO) ""
	@$(ECHO) "   % make compile [hdl=/path/to/verilog.v|hdl=/path/to/vhdl.vhd]"
	@$(ECHO) "   % make sim [mode=gui|tcl|batch]"
	@$(ECHO) "   % make build"
	@$(ECHO) "   % make install"
	@$(ECHO) "   % make install/flash [board=Arty|ArtyA7]"
	@$(ECHO) "   % make build/restore dcp=work/build/outputs/mapped.dcp [mode=gui|tcl]\n\n"

#####______________________________________________________________________________________________________________________________


##############################
##   IP-generation target   ##
##############################

## empty variable to optionally specify a Xilinx Core Instance (.xci) configuration file
xci :=

ifneq ($(xci),)
   export XCI_FILE=$(xci)
endif

## Launch Vivado IP flow in GUI mode or compile IP from XCI file (make ip xci=/path/to/IP.xci)
.PHONY : ip
ip : $(TCL_DIR)/common/init.tcl $(TCL_DIR)/common/ip.tcl ## open ip vivado set up

ifeq ($(wildcard $(IPS_DIR)/.*),)
	@$(error ERROR: Missing IPs directory ! Run 'make area' before running the flows.)
else
ifeq ($(mode),gui)
	@echo "exec vivado -mode gui \
	   -source $(TCL_DIR)/common/init.tcl -source $(TCL_DIR)/common/ip.tcl \
	   -notrace -log $(LOG_DIR)/$@.log -nojournal &" | tclsh -norc
else
	@vivado -mode $(mode) \
	   -source $(TCL_DIR)/common/init.tcl -source $(TCL_DIR)/common/ip.tcl \
	   -notrace -log $(LOG_DIR)/$@.log -nojournal
endif
endif

#####______________________________________________________________________________________________________________________________

####################################
## Target to open VIVADO GUI mode ##
####################################

.PHONY : gui
gui :  ## Open vivado in GUI mode

	@echo "exec vivado -mode gui &" | tclsh -norc

##############################
## chiusura vivado da shell ##
##############################

.PHONY : exit
exit : $(TCL_DIR)/sim/exit.tcl ##chiusura vivado da shell

	@echo "chiusura vivado..."

##################################################
## COPY all .ctl and sub-makefiles form std_dir ##
##################################################

.PHONY : copy
copy : ## copy all scripts from std_dir

	@echo "copying all scripts..."
	@cp ../rehab/Std_Dir/scripts/build/*.tcl scripts/build/
	@cp ../rehab/Std_Dir/scripts/common/*.tcl scripts/common/
	@cp ../rehab/Std_Dir/scripts/sim/*.tcl scripts/sim/
	@cp ../rehab/Std_Dir/scripts/debug/*.tcl scripts/debug/
	@cp ../rehab/Std_Dir/scripts/install/*.tcl scripts/install/
	@cp ../rehab/Std_Dir/scripts/build/Makefile.build scripts/build/
	@cp ../rehab/Std_Dir/scripts/install/Makefile.install scripts/install/
	@cp ../rehab/Std_Dir/scripts/sim/Makefile.sim scripts/sim/
	@echo "all scripts copied..."

###########################################################
## CLEAN ALL target to clean compleatly the working area ##
###########################################################

.PHONY : clean/all
clean/all : sim/clean build/clean ## Delete ALL temporary and garbage files

	@$(RM) *.pb *.wdb *.log *.jou *.str *xpr *.xml *.bit *.bin
	@$(RMDIR) xsim.dir
	@$(RMDIR) .Xil
	@echo "all file deleted"

.PHONY : clean
clean : ##elimina file nella prima directory (.jou, .log)

	@$(RM) *.log *.jou *.wcfg
	@echo "file deleted"
##__________________________________________________________________________________________________________________________________

