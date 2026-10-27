`timescale 1ns / 1ps
`default_nettype none

module adder (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [15:0] sum
);
    assign sum = a + b;
endmodule
`default_nettype wire
