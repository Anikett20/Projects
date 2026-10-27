`timescale 1ns / 1ps
`default_nettype none

module program_counter (
    input  wire        clk,
    input  wire        rst,
    input  wire        pc_write,
    input  wire [15:0] pc_in,
    output reg  [15:0] pc_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out <= 16'h0000;
        end else if (pc_write) begin
            pc_out <= pc_in;
        end
    end

endmodule
`default_nettype wire
