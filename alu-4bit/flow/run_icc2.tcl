# 1. Setup Library and Design
set PDK_PATH "./../ref"
create_lib -ref_lib $PDK_PATH/lib/ndm/saed32rvt_c.ndm ALU_LIB

# 2. Read the synthesized netlist from the DC results folder
read_verilog {./../DC/results/alu_4bit_synthesized.v} -library ALU_LIB -top alu_4bit

# 3. Initialize the Floorplan
# core_utilization 0.6 means 60% of the area is for gates, 40% for routing
initialize_floorplan -core_utilization 0.6 -core_offset {10}

# 4. Place I/O Pins
# This organizes pins on different sides of the chip
set_individual_pin_constraints -ports [get_ports a*] -sides 1
set_individual_pin_constraints -ports [get_ports b*] -sides 2
set_individual_pin_constraints -ports [get_ports {result carry_out zero}] -sides 3
set_individual_pin_constraints -ports [get_ports {clk rst}] -sides 4
place_pins -self

# 5. Create basic placement to see cell distribution
create_placement -floorplan

# 6. Save the block
save_block -as ALU_FLOORPLAN