OUT      := $(RTL_MODULE_DIR)/out
WORK     := work
CLOG     := compile.log
SLOG     := sim.log

TOP      := testbench
DUT      := dut
IFACE    := skb_if

DO       := do.tcl 
WAVES    := 1
SIM_OPTS := -gui

RTL_MODULES = $(shell ls -d */ | sed 's/\///')

export OUT
export WORK
export LOG
export TOP
export DUT
export IFACE
export WAVES
export SIM_OPTS

#v=@

ifeq ($(RTL_MODULE_DIR),)
  $(info Need to specify RTL module for testing, possible RTLs are:)
  $(info )
  $(info $(RTL_MODULES))
  $(info )
  $(error RTL_MODULE_DIR is not set)
endif

ifeq ($(RTL_MODULE_DIR), skid-buffer)
  RTL="RTL1=1"
endif

ifeq ($(RTL_MODULE_DIR), pipe-skid-buffer)
  RTL="RTL2=1"
endif

SRC_VERILOG=$(shell find $(RTL_MODULE) -name "*.v")
SRC_SV=tb.sv

$(OUT)/compile.stamp: $(SRC_SV) $(SRC_VERILOG) $(OUT)
	@echo "Compile sources..."
	$(v)vlib $(OUT)/$(WORK) > $(OUT)/$(CLOG)
	$(v)vmap work $(OUT)/$(WORK) >> $(OUT)/$(CLOG)
	$(v)vlog -define $(RTL) -sv -work $(WORK) $(SRC_SV) $(SRC_VERILOG) >> $(OUT)/$(CLOG)
	@touch $@

$(OUT):
	@echo "Create $(OUT)..."
	mkdir -p $@

sim: $(OUT)/compile.stamp
	@echo "Run simulation..."
	$(v)vsim $(SIM_OPTS) work.$(TOP) -work $(OUT)/$(WORK) -do $(DO) \
                -voptargs="+acc" -l $(OUT)/$(SLOG) -wlf $(OUT)/sim.wlf > $(OUT)/$(SLOG)

default: $(OUT)/compile.stamp
	@echo "all target"

clean:
	@echo "Clean up build..."
	@rm -rvf $(OUT)

.PHONY: default clean
