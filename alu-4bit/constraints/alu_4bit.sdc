###################################################################

# Created by write_sdc on Sat Feb 14 04:48:10 2026

###################################################################
set sdc_version 2.1

set_units -time ns -resistance MOhm -capacitance fF -voltage V -current uA
create_clock [get_ports clk]  -period 1.2  -waveform {0 0.6}
set_input_delay -clock clk  0.2  [get_ports clk]
set_input_delay -clock clk  0.2  [get_ports rst]
set_input_delay -clock clk  0.2  [get_ports {a[3]}]
set_input_delay -clock clk  0.2  [get_ports {a[2]}]
set_input_delay -clock clk  0.2  [get_ports {a[1]}]
set_input_delay -clock clk  0.2  [get_ports {a[0]}]
set_input_delay -clock clk  0.2  [get_ports {b[3]}]
set_input_delay -clock clk  0.2  [get_ports {b[2]}]
set_input_delay -clock clk  0.2  [get_ports {b[1]}]
set_input_delay -clock clk  0.2  [get_ports {b[0]}]
set_input_delay -clock clk  0.2  [get_ports {opcode[2]}]
set_input_delay -clock clk  0.2  [get_ports {opcode[1]}]
set_input_delay -clock clk  0.2  [get_ports {opcode[0]}]
set_output_delay -clock clk  0.2  [get_ports {result[3]}]
set_output_delay -clock clk  0.2  [get_ports {result[2]}]
set_output_delay -clock clk  0.2  [get_ports {result[1]}]
set_output_delay -clock clk  0.2  [get_ports {result[0]}]
set_output_delay -clock clk  0.2  [get_ports carry_out]
set_output_delay -clock clk  0.2  [get_ports zero]
