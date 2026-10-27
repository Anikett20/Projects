`timescale 1ns / 1ps
// ============================================================================
// 32-Bit Simple Structural Synchronous FIFO (fifo_memo)
// ============================================================================
`default_nettype none

module fifo_memo(
    input  wire        wr,
    input  wire        rd,
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] data_in,
    output wire [31:0] data_out,
    output wire        fifo_full,
    output wire        fifo_empty,
    output wire        fifo_th,
    output wire        fifo_ovf,
    output wire        fifo_ufl
);

    wire [4:0] wptr, rptr;
    wire       fifo_we, fifo_rd;

    write_pointer u_wr_ptr (
        .wptr      (wptr),
        .fifo_we   (fifo_we),
        .wr        (wr),
        .fifo_full (fifo_full),
        .clk       (clk),
        .rst_n     (rst_n)
    );

    read_pointer u_rd_ptr (
        .rptr       (rptr),
        .fifo_rd    (fifo_rd),
        .rd         (rd),
        .fifo_empty (fifo_empty),
        .clk        (clk),
        .rst_n      (rst_n)
    );

    memory_array u_mem (
        .data_in  (data_in),
        .data_out (data_out),
        .clk      (clk),
        .rst_n    (rst_n),
        .fifo_we  (fifo_we),
        .wptr     (wptr),
        .rptr     (rptr)
    );

    status_signal u_status (
        .fifo_full  (fifo_full),
        .fifo_empty (fifo_empty),
        .fifo_th    (fifo_th),
        .fifo_ovf   (fifo_ovf),
        .fifo_ufl   (fifo_ufl),
        .wr         (wr),
        .rd         (rd),
        .fifo_we    (fifo_we),
        .fifo_rd    (fifo_rd),
        .wptr       (wptr),
        .rptr       (rptr),
        .clk        (clk),
        .rst_n      (rst_n)
    );

endmodule

module memory_array(
    input  wire [31:0] data_in,
    input  wire        clk,
    input  wire        rst_n,
    input  wire        fifo_we,
    input  wire [4:0]  wptr,
    input  wire [4:0]  rptr,
    output wire [31:0] data_out
);

    reg [31:0] mem [0:15];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (i = 0; i < 16; i = i + 1) begin
                mem[i] <= 32'h0000_0000;
            end
        end else if (fifo_we) begin
            mem[wptr[3:0]] <= data_in;
        end
    end

    assign data_out = mem[rptr[3:0]];

endmodule

module read_pointer(
    input  wire       rd,
    input  wire       fifo_empty,
    input  wire       clk,
    input  wire       rst_n,
    output reg  [4:0] rptr,
    output wire       fifo_rd
);

    assign fifo_rd = (~fifo_empty) & rd;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            rptr <= 5'd0;
        else if (fifo_rd)
            rptr <= rptr + 5'd1;
    end

endmodule

module write_pointer(
    input  wire       wr,
    input  wire       fifo_full,
    input  wire       clk,
    input  wire       rst_n,
    output reg  [4:0] wptr,
    output wire       fifo_we
);

    assign fifo_we = (~fifo_full) & wr;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            wptr <= 5'd0;
        else if (fifo_we)
            wptr <= wptr + 5'd1;
    end

endmodule

module status_signal(
    input  wire       wr,
    input  wire       rd,
    input  wire       fifo_we,
    input  wire       fifo_rd,
    input  wire [4:0] wptr,
    input  wire [4:0] rptr,
    input  wire       clk,
    input  wire       rst_n,
    output reg        fifo_full,
    output reg        fifo_empty,
    output reg        fifo_th,
    output reg        fifo_ovf,
    output reg        fifo_ufl
);

    wire fbit_comp;
    wire ptr_equal;
    wire [4:0] ptr_result;
    wire ovf_set, ufl_set;

    assign fbit_comp  = wptr[4] ^ rptr[4];
    assign ptr_equal  = (wptr[3:0] == rptr[3:0]);
    assign ptr_result = wptr[4:0] - rptr[4:0];
    assign ovf_set    = fifo_full & wr;
    assign ufl_set    = fifo_empty & rd;

    always @(*) begin
        fifo_full  = fbit_comp & ptr_equal;
        fifo_empty = ~fbit_comp & ptr_equal;
        fifo_th    = (ptr_result >= 5'd8);
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            fifo_ovf <= 1'b0;
        else if (ovf_set && ~fifo_rd)
            fifo_ovf <= 1'b1;
        else if (fifo_rd)
            fifo_ovf <= 1'b0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            fifo_ufl <= 1'b0;
        else if (ufl_set && ~fifo_we)
            fifo_ufl <= 1'b1;
        else if (fifo_we)
            fifo_ufl <= 1'b0;
    end

endmodule
`default_nettype wire
