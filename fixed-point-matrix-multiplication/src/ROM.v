`timescale 1ns / 1ps
// =============================================================================
// File        : ROM.v
// Project     : 4x4 Fixed-Point Matrix Multiplication (OpenLane SKY130 Target)
// Description : 16x16-bit Q7.8 Fixed-Point Input Matrix B LUT ROM
//               Row 0: [ +2.00 (0x0200), -0.50 (0x8080), +1.00 (0x0100), +1.50 (0x0180) ]
//               Row 1: [ +1.00 (0x0100), +2.50 (0x0280), -1.25 (0x8140), +0.50 (0x0080) ]
//               Row 2: [ -1.50 (0x8180), +1.00 (0x0100), +2.00 (0x0200), -0.75 (0x80C0) ]
//               Row 3: [ +0.50 (0x0080), -1.00 (0x8100), +0.50 (0x0080), +2.00 (0x0200) ]
// =============================================================================
`default_nettype none

module ROM (
    input  wire        clka,
    input  wire [3:0]  addra,
    output reg  [15:0] douta
);

    wire _unused_ok = clka;

    always @(*) begin
        case (addra)
            4'd0:  douta = 16'h0200; // +2.00
            4'd1:  douta = 16'h8080; // -0.50
            4'd2:  douta = 16'h0100; // +1.00
            4'd3:  douta = 16'h0180; // +1.50
            4'd4:  douta = 16'h0100; // +1.00
            4'd5:  douta = 16'h0280; // +2.50
            4'd6:  douta = 16'h8140; // -1.25
            4'd7:  douta = 16'h0080; // +0.50
            4'd8:  douta = 16'h8180; // -1.50
            4'd9:  douta = 16'h0100; // +1.00
            4'd10: douta = 16'h0200; // +2.00
            4'd11: douta = 16'h80C0; // -0.75
            4'd12: douta = 16'h0080; // +0.50
            4'd13: douta = 16'h8100; // -1.00
            4'd14: douta = 16'h0080; // +0.50
            4'd15: douta = 16'h0200; // +2.00
            default: douta = 16'h0000;
        endcase
    end

endmodule
`default_nettype wire
