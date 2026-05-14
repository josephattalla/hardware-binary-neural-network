# constraints.xdc
# Not instantiating a clock will automatically prompt the implementation
# To use maximum frequency, it consumed more power that the device can handle
# total on chip power is 189.965 W (junction temp exceeded), junction temperature 125 C, and thermal margin is -88.2 C (-100.3W) 
# 50 MHz clock - 20ns period - FMAX is 89.7 MHz
create_clock -period 20.000 -name sys_clk [get_ports clk]

# Input and output delay margins
set_input_delay  -clock sys_clk 2.000 [get_ports {start pixel_in[*]}]
set_output_delay -clock sys_clk 2.000 [get_ports {classification[*] done}]S