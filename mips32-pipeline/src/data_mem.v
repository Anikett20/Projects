`timescale 1ns / 1ps
// =============================================================================
// File        : data_mem.v
// Project     : 32-bit 5-Stage Pipelined MIPS Processor (OpenLane SKY130)
// Description : Synthesizable 16x32-bit Word-Aligned Data Memory with Reset
// =============================================================================

module dataMem(
    output wire [31:0] data,
    input  wire [31:0] address,
    input  wire [31:0] writedata,
    input  wire        writeenable,
    input  wire        MemRead,
    input  wire        reset,
    input  wire        clk
);

    wire _unused_ok = &{1'b0, address[31:6], address[1:0]};

    reg [31:0] datamem [0:15];
    integer i;

    assign data = MemRead ? datamem[address[5:2]] : 32'h00000000;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 16; i = i + 1) begin
                datamem[i] <= 32'h00000000;
            end
        end else if (writeenable) begin
            datamem[address[5:2]] <= writedata;
        end
    end

endmodule
