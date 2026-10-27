`timescale 1ns / 1ps
// ============================================================================
// File        : fifo_memory.v
// Project     : 32-Bit Synchronous FIFO Memory (OpenLane SKY130 Target)
// Description : Parameterized 32-Bit Synchronous FIFO (16x32-bit Default)
//               - 32-bit Data Bus (data_in[31:0], data_out[31:0])
//               - Gray-coded read/write pointers (wr_ptr_gray, rd_ptr_gray)
//               - Status flags: fifo_full, fifo_empty, fifo_th, fifo_ovf, fifo_ufl
//               - Deterministic active-low reset (rst_n) for ASIC synthesis
// ============================================================================
`default_nettype none

module fifo_memory #(
    parameter DEPTH      = 16,
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4,
    parameter THRESHOLD  = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  wr_en,
    input  wire                  rd_en,
    input  wire [DATA_WIDTH-1:0] data_in,
    output reg  [DATA_WIDTH-1:0] data_out,
    output wire                  fifo_full,
    output wire                  fifo_empty,
    output wire                  fifo_th,
    output reg                   fifo_ovf,
    output reg                   fifo_ufl
);

    reg [ADDR_WIDTH:0] wr_ptr_gray, wr_ptr_gray_next;
    reg [ADDR_WIDTH:0] rd_ptr_gray, rd_ptr_gray_next;
    reg [ADDR_WIDTH:0] wr_ptr_bin,  wr_ptr_bin_next;
    reg [ADDR_WIDTH:0] rd_ptr_bin,  rd_ptr_bin_next;

    wire                wr_en_int;
    wire                rd_en_int;
    wire [ADDR_WIDTH:0] fifo_count;

    // 16 x 32-bit synchronous storage array
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    integer k;

    function [ADDR_WIDTH:0] bin2gray;
        input [ADDR_WIDTH:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Write pointer logic
    assign wr_en_int = wr_en & ~fifo_full;

    always @(*) begin
        wr_ptr_bin_next  = wr_ptr_bin + {{ADDR_WIDTH{1'b0}}, wr_en_int};
        wr_ptr_gray_next = bin2gray(wr_ptr_bin_next);
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            wr_ptr_bin  <= {(ADDR_WIDTH+1){1'b0}};
            wr_ptr_gray <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            wr_ptr_bin  <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;
        end
    end

    // Read pointer logic
    assign rd_en_int = rd_en & ~fifo_empty;

    always @(*) begin
        rd_ptr_bin_next  = rd_ptr_bin + {{ADDR_WIDTH{1'b0}}, rd_en_int};
        rd_ptr_gray_next = bin2gray(rd_ptr_bin_next);
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            rd_ptr_bin  <= {(ADDR_WIDTH+1){1'b0}};
            rd_ptr_gray <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            rd_ptr_bin  <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;
        end
    end

    // Synchronous 32-bit memory write & reset
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (k = 0; k < DEPTH; k = k + 1) begin
                mem[k] <= {DATA_WIDTH{1'b0}};
            end
        end else if (wr_en_int) begin
            mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= data_in;
        end
    end

    // Registered 32-bit output read
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_out <= {DATA_WIDTH{1'b0}};
        end else begin
            data_out <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
        end
    end

    // FIFO occupancy count & status flags
    assign fifo_count = wr_ptr_bin - rd_ptr_bin;
    assign fifo_empty = (fifo_count == {(ADDR_WIDTH+1){1'b0}});
    assign fifo_full  = (fifo_count == DEPTH[ADDR_WIDTH:0]);
    assign fifo_th    = (fifo_count >= THRESHOLD[ADDR_WIDTH:0]);

    // Sticky overflow & underflow flags
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            fifo_ovf <= 1'b0;
        end else if (wr_en & fifo_full) begin
            fifo_ovf <= 1'b1;
        end else if (rd_en_int) begin
            fifo_ovf <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            fifo_ufl <= 1'b0;
        end else if (rd_en & fifo_empty) begin
            fifo_ufl <= 1'b1;
        end else if (wr_en_int) begin
            fifo_ufl <= 1'b0;
        end
    end

endmodule
`default_nettype wire
