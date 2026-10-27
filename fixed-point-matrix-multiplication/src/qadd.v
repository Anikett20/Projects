`timescale 1ns / 1ps
// =============================================================================
// File        : qadd.v
// Project     : 4x4 Fixed-Point Matrix Multiplication (OpenLane SKY130 Target)
// Description : Parameterized Q(N-Q-1).Q Sign-Magnitude Fixed-Point Adder
//               Format: |[N-1] Sign | [N-2:Q] Integer | [Q-1:0] Fraction |
// =============================================================================
`default_nettype none

module qadd #(
    parameter Q = 8,
    parameter N = 16
)(
    input  wire [N-1:0] a,
    input  wire [N-1:0] b,
    output reg  [N-1:0] c
);

    reg [N-2:0] mag_sum;
    reg         sign_out;

    always @(*) begin
        if (a[N-1] == b[N-1]) begin
            // Same sign: add magnitudes and keep common sign (unless zero)
            mag_sum  = a[N-2:0] + b[N-2:0];
            sign_out = (mag_sum == {(N-1){1'b0}}) ? 1'b0 : a[N-1];
            c        = {sign_out, mag_sum};
        end else begin
            // Opposite signs: subtract smaller magnitude from larger magnitude
            if (a[N-2:0] > b[N-2:0]) begin
                mag_sum  = a[N-2:0] - b[N-2:0];
                sign_out = a[N-1];
                c        = {sign_out, mag_sum};
            end else if (b[N-2:0] > a[N-2:0]) begin
                mag_sum  = b[N-2:0] - a[N-2:0];
                sign_out = b[N-1];
                c        = {sign_out, mag_sum};
            end else begin
                // Equal magnitudes with opposite signs cancel to +0
                mag_sum  = {(N-1){1'b0}};
                sign_out = 1'b0;
                c        = {N{1'b0}};
            end
        end
    end

endmodule
`default_nettype wire
