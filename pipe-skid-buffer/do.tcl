# Import environment variables
set TOP   $::env(TOP)
set DUT   $::env(DUT)
set OUT   $::env(OUT)
set IFACE $::env(IFACE)
set WAVES $::env(WAVES)

# Create VCD
if $WAVES {
    vcd file $OUT/sim.vcd;
    vcd add $TOP/*
}

# Run
#if { ![batch_mode] && $WAVES } {add wave -position end sim:/$TOP/$IFACE/*};
if { ![batch_mode] && $WAVES } {add wave -position end sim:/$TOP/$DUT/*};
run -a;
if { ![batch_mode] && $WAVES } {config wave -signalnamewidth 1; wave zoom full};
if  [batch_mode] {exit -force};
