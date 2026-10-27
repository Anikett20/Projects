`timescale 1ns / 1ps
// fpga4student.com: FPGA projects, Verilog Projects, VHDL projects
// Verilog project: 32-bit 5-stage Pipelined MIPS Processor in Verilog 
// Control singals for JR instruction
module JRControl_Block( JRControl, ALUOp, Function);
output JRControl;
reg JRControl;
input [1:0] ALUOp;
input [5:0] Function;
wire [7:0] test;
assign test = {ALUOp,Function};
always @(*)
case (test)
 8'b10001000 : JRControl=1'b1; 
 default: JRControl=1'b0;
 endcase
endmodule
