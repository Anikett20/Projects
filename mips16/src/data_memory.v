`timescale 1ns / 1ps
// =============================================================================
// File        : data_memory.v
// Project     : 16-bit MIPS Single-Cycle Processor (OpenLane SKY130 Target)
// Description : Synthesizable 16x16-bit Synchronous Data Memory with Reset
// =============================================================================
`default_nettype none

module data_memory (
    input  wire        clk,
    input  wire        rst,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [15:0] address,
    input  wire [15:0] write_data,
    output wire [15:0] read_data
);

    wire _unused_ok = &{1'b0, address[15:5], address[0]};

    reg [15:0] memory [0:15];
    integer i;

    assign read_data = mem_read ? memory[address[4:1]] : 16'h0000;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            memory[0] <= 16'h1234;
            memory[1] <= 16'h5678;
            for (i = 2; i < 16; i = i + 1) begin
                memory[i] <= 16'h0000;
            end
        end else if (mem_write) begin
            memory[address[4:1]] <= write_data;
        end
    end

endmodule
`default_nettype wire
