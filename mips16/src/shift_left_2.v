`timescale 1ns / 1ps
`default_nettype none

module shift_left_2 (
    input  wire [15:0] in,
    output wire [15:0] out
);
    assign out = in << 2;
endmodule
`default_nettype wire
