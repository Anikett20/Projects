`timescale 1ns / 1ps
// =============================================================================
// File        : matrix_out.v
// Project     : 4x4 Fixed-Point Matrix Multiplication (OpenLane SKY130 Target)
// Description : 16x16-bit Synchronous Output Matrix RAM with Registered Read
// =============================================================================
`default_nettype none

module matrix_out (
    input  wire        clka,
    input  wire [3:0]  addra,
    output reg  [15:0] douta,
    input  wire        wea,
    input  wire [15:0] dina
);

    reg [15:0] mem [0:15];
    integer k;

    initial begin
        for (k = 0; k < 16; k = k + 1) begin
            mem[k] = 16'h0000;
        end
        douta = 16'h0000;
    end

    always @(posedge clka) begin
        if (wea) begin
            mem[addra] <= dina;
            douta      <= dina;
        end else begin
            douta      <= mem[addra];
        end
    end

endmodule
`default_nettype wire
