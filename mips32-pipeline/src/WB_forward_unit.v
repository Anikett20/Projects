`timescale 1ns / 1ps
// fpga4student.com: FPGA projects, Verilog Projects, VHDL projects
// Verilog project: 32-bit 5-stage Pipelined MIPS Processor in Verilog 
// Write Back Forwarding 
module WB_forward(ReadData1Out,ReadData2Out,ReadData1,ReadData2,rs,rt,WriteRegister,WriteData,RegWrite);
// WB Hazard: Reading data while writing 
// Solve Hazard at the WriteBack Stage
output [31:0] ReadData1Out,ReadData2Out;
input [31:0] ReadData1,ReadData2,WriteData;
input [4:0] rs,rt,WriteRegister;
input RegWrite;
wire ReadSourceRs,ReadSourceRt;
wire compOut1,compOut2;
// behavior model
/*
always @(rs or rt or WriteRegister or WriteData or RegWrite)
begin
 if ((RegWrite==1)&&(WriteRegister != 0)&&(WriteRegister==rs))
  ReadSourceRs = 1'b1; //Forwarding WriteData to ReadData1
  else 
  ReadSourceRs = 1'b0;
  if ((RegWrite==1)&&(WriteRegister != 0)&&(WriteRegister==rt))
  ReadSourceRt = 1'b1; //Forwarding WriteData to ReadData2
  else 
  ReadSourceRt = 1'b0;
end
*/
// Structural model
or  orWriteReg(orOut1,WriteRegister[4],WriteRegister[3],WriteRegister[2],WriteRegister[1],WriteRegister[0]);
CompareAddress Compare1(compOut1,WriteRegister,rs);
and  andCondition1(ReadSourceRs,RegWrite,orOut1,compOut1);

CompareAddress Compare2(compOut2,WriteRegister,rt);
and  andCondition2(ReadSourceRt,RegWrite,orOut1,compOut2);

mux2x32to32 muxReadData1( ReadData1Out,ReadData1,WriteData, ReadSourceRs);
mux2x32to32 muxReadData2( ReadData2Out,ReadData2,WriteData, ReadSourceRt);
endmodule
`timescale 1ns / 1ps
module CompareAddress(equal,Addr1,Addr2);
// fpga4student.com: FPGA projects, Verilog Projects, VHDL projects
// Verilog project: 32-bit 5-stage Pipelined MIPS Processor in Verilog 
// Compare Address
output equal;
wire equal;
input [4:0] Addr1,Addr2;
wire [4:0] Addr1,Addr2,xorAddress;
xor  xorAddress4(xorAddress[4],Addr1[4],Addr2[4]);
xor  xorAddress3(xorAddress[3],Addr1[3],Addr2[3]);
xor  xorAddress2(xorAddress[2],Addr1[2],Addr2[2]);
xor  xorAddress1(xorAddress[1],Addr1[1],Addr2[1]);
xor  xorAddress0(xorAddress[0],Addr1[0],Addr2[0]);
or  Orgate1(OrAddr,xorAddress[4],xorAddress[3],xorAddress[2],xorAddress[1],xorAddress[0]);
not  notgate1(equal,OrAddr);
endmodule
