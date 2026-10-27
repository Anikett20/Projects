`timescale 1ns / 1ps
// =============================================================================
// File        : qmult.v
// Project     : 4x4 Fixed-Point Matrix Multiplication (OpenLane SKY130 Target)
// Description : Parameterized Q(N-Q-1).Q Sign-Magnitude Fixed-Point Multiplier
//               Format: |[N-1] Sign | [N-2:Q] Integer | [Q-1:0] Fraction |
// =============================================================================
`default_nettype none

module qmult #(
    parameter Q = 8,
    parameter N = 16
)(
    input  wire [N-1:0] i_multiplicand,
    input  wire [N-1:0] i_multiplier,
    output wire [N-1:0] o_result,
    output wire         ovr
);

    // 2*(N-1)-bit unsigned magnitude product
    wire [2*N-3:0] r_ext;
    wire [N-2:0]   quantized_mag;
    wire           res_sign;

    assign r_ext         = i_multiplicand[N-2:0] * i_multiplier[N-2:0];
    assign quantized_mag = r_ext[N-2+Q : Q];

    // Zero result forces positive sign (0) to avoid negative zero (0x8000)
    assign res_sign      = (quantized_mag == {(N-1){1'b0}}) ? 1'b0 : (i_multiplicand[N-1] ^ i_multiplier[N-1]);
    assign o_result      = {res_sign, quantized_mag};

    // Overflow asserts if any upper integer bits above [N-2+Q] are non-zero
    assign ovr           = |r_ext[2*N-3 : N-1+Q];

endmodule
`default_nettype wire
