OUT      := out
WORK     := work
CLOG     := compile.log
SLOG     := sim.log

TOP      := testbench
DUT      := dut
IFACE    := skb_if

DO       := do.tcl 
WAVES    := 1
SIM_OPTS := -gui

export OUT
export WORK
export LOG
export TOP
export DUT
export IFACE
export WAVES
export SIM_OPTS

#v=@

SRC_VERILOG=$(shell find . -name "*.v")
SRC_SV=$(shell find . -name "*.sv")

$(OUT)/compile.stamp: $(SRC_SV) $(SRC_VERILOG) $(OUT)
	@echo "Compile sources..."
	$(v)vlib $(OUT)/$(WORK) > $(OUT)/$(CLOG)
	$(v)vmap work $(OUT)/$(WORK) >> $(OUT)/$(CLOG)
	$(v)vlog -sv -work $(WORK) $(SRC_SV) $(SRC_VERILOG) >> $(OUT)/$(CLOG)
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
