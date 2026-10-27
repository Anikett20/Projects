`timescale 1ns / 1ps
`default_nettype none

module mux2to1_16 (
    input  wire [15:0] in0,
    input  wire [15:0] in1,
    input  wire        sel,
    output wire [15:0] out
);
    assign out = sel ? in1 : in0;
endmodule

module mux2to1_3 (
    input  wire [2:0] in0,
    input  wire [2:0] in1,
    input  wire       sel,
    output wire [2:0] out
);
    assign out = sel ? in1 : in0;
endmodule

module mux4to1_16 (
    input  wire [15:0] in0,
    input  wire [15:0] in1,
    input  wire [15:0] in2,
    input  wire [15:0] in3,
    input  wire [1:0]  sel,
    output wire [15:0] out
);
    assign out = (sel == 2'b00) ? in0 :
                 (sel == 2'b01) ? in1 :
                 (sel == 2'b10) ? in2 : in3;
endmodule

module mux2to1_1 (
    input  wire in0,
    input  wire in1,
    input  wire sel,
    output wire out
);
    assign out = sel ? in1 : in0;
endmodule
`default_nettype wire
