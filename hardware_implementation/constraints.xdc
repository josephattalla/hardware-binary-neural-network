# constraints.xdc
#
# Without a clock constraint Vivado estimates power at the maximum frequency the device
# can sustain, producing 189.965W total on-chip power, exceeded junction temperature
# (125 C), and a thermal margin of -88.2 C. A constrained clock fixes this.
#
# Fmax after pipelining the 784-bit popcount
# before pipelining: 38 MHz  (single 784-deep carry chain and 26ns critical path)
# after pipelining: 82 MHz (argmax tree)

# 82 MHz clock: 12.2 ns period
create_clock -period 12.200 -name sys_clk [get_ports clk]

# input timing: pixel_in and start must be stable 2ns before the rising clock edge
set_input_delay -clock sys_clk 2.000 [get_ports {start pixel_in[*]}]
