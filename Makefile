OUT      := $(TEST)/out
WORK     := work
CLOG     := compile.log
SLOG     := sim.log

TOP      := testbench
DUT      := dut
IFACE    := skb_if

DO       := do.tcl 
WAVES    := 1
SIM_OPTS := -gui

TEST_RTL := $(shell echo $(TEST) | tr '[:lower:]' '[:upper:]' | tr '-' '_')=1

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

ifeq ($(TEST),)
  $(info Need to specify TEST module for testing, possible modules are:)
  $(info )
  $(foreach dut, $(RTL_MODULES), $(info $(dut)))
  $(info )
  $(error TEST is not set)
endif

SRC_VERILOG=$(shell find $(RTL_MODULE) -name "*.v")
SRC_SV=tb.sv

$(OUT)/compile.stamp: $(SRC_SV) $(SRC_VERILOG) $(OUT)
	@echo "Compile sources..."
	@echo $(TEST1)
	$(v)vlib $(OUT)/$(WORK) > $(OUT)/$(CLOG)
	$(v)vmap work $(OUT)/$(WORK) >> $(OUT)/$(CLOG)
	$(v)vlog -define $(TEST_RTL) -sv -work $(WORK) $(SRC_SV) $(SRC_VERILOG) >> $(OUT)/$(CLOG)
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
