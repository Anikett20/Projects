`timescale 1ns / 1ps
// =============================================================================
// File        : Matrix_A.v
// Project     : 4x4 Fixed-Point Matrix Multiplication (OpenLane SKY130 Target)
// Description : 16x16-bit Q7.8 Fixed-Point Input Matrix A LUT ROM
//               Row 0: [ +1.50 (0x0180), +2.00 (0x0200), -1.00 (0x8100), +0.50 (0x0080) ]
//               Row 1: [ +0.25 (0x0040), -1.50 (0x8180), +2.50 (0x0280), +1.00 (0x0100) ]
//               Row 2: [ +3.00 (0x0300), +0.75 (0x00C0), +1.25 (0x0140), -2.00 (0x8200) ]
//               Row 3: [ -0.50 (0x8080), +1.00 (0x0100), -1.50 (0x8180), +2.25 (0x0240) ]
// =============================================================================
`default_nettype none

module Matrix_A (
    input  wire        clka,
    input  wire [3:0]  addra,
    output reg  [15:0] douta
);

    // Unused clock port kept for Xilinx BRAM IP interface compatibility
    wire _unused_ok = clka;

    always @(*) begin
        case (addra)
            4'd0:  douta = 16'h0180; // +1.50
            4'd1:  douta = 16'h0200; // +2.00
            4'd2:  douta = 16'h8100; // -1.00
            4'd3:  douta = 16'h0080; // +0.50
            4'd4:  douta = 16'h0040; // +0.25
            4'd5:  douta = 16'h8180; // -1.50
            4'd6:  douta = 16'h0280; // +2.50
            4'd7:  douta = 16'h0100; // +1.00
            4'd8:  douta = 16'h0300; // +3.00
            4'd9:  douta = 16'h00C0; // +0.75
            4'd10: douta = 16'h0140; // +1.25
            4'd11: douta = 16'h8200; // -2.00
            4'd12: douta = 16'h8080; // -0.50
            4'd13: douta = 16'h0100; // +1.00
            4'd14: douta = 16'h8180; // -1.50
            4'd15: douta = 16'h0240; // +2.25
            default: douta = 16'h0000;
        endcase
    end

endmodule
`default_nettype wire
