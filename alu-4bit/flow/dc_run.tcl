# 1. Setup and Library Definitions
# (Ensure your library paths match your college server setup, standard for SAED32)
# source -echo -verbose ./rm_setup/dc_setup.tcl 

# 2. Read the RTL Design
set RTL_SOURCE_FILES "alu_4bit.v"
set DESIGN_NAME "alu_4bit"

analyze -format verilog ${RTL_SOURCE_FILES}
elaborate ${DESIGN_NAME}
current_design ${DESIGN_NAME}

# 3. Apply Constraints (1.2ns clock)
create_clock -name clk -period 1.2 [get_ports clk]
set_input_delay 0.2 -clock clk [all_inputs]
set_output_delay 0.2 -clock clk [all_outputs]

# 4. Prevent tool from using certain complex cells
set_dont_use [get_lib_cells */FADD*]
set_dont_use [get_lib_cells */HADD*]
set_dont_use [get_lib_cells */AO*]
set_dont_use [get_lib_cells */OA*]
set_dont_use [get_lib_cells */NAND*]
set_dont_use [get_lib_cells */XOR*]
set_dont_use [get_lib_cells */NOR*]
set_dont_use [get_lib_cells */XNOR*]
set_dont_use [get_lib_cells */MUX*]

# 5. Compile the Design
compile_ultra

# 6. Generate Reports
report_timing > timing_report.txt
report_qor > qor_report.txt
report_area > area_report.txt

# 7. Save the Synthesized Netlist
write -format verilog -hierarchy -output alu_4bit_synthesized.v
write_sdc alu_4bit.sdc