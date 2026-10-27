`timescale 1ns / 1ps
// =============================================================================
// File        : mips16.v
// Project     : 16-bit MIPS Single-Cycle Processor (OpenLane SKY130 Target)
// Description : Top-Level 16-Bit Single-Cycle MIPS Processor
//               Fixes BNE branch condition, JAL link-register ($7) writeback,
//               and integrates synthesizable instruction ROM & data RAM.
// =============================================================================
`default_nettype none

module mips16 (
    input  wire        clk,
    input  wire        rst,
    output wire [15:0] pc_out,
    output wire [15:0] instruction,
    output wire [15:0] alu_result,
    output wire [15:0] read_data1,
    output wire [15:0] read_data2,
    output wire [15:0] write_data,
    output wire        zero_flag,
    output wire [2:0]  write_reg
);

    wire [15:0] pc_next;
    wire [15:0] pc_plus2;
    wire [15:0] pc_branch;
    wire [15:0] pc_jump;
    wire [15:0] branch_offset;
    wire [15:0] sign_ext_imm;
    wire [15:0] alu_in2;
    wire [15:0] mem_read_data;
    wire [15:0] wb_mux_data;
    wire [15:0] reg_write_data;
    wire [2:0]  rd_or_rt;
    wire [2:0]  reg_dst_mux_out;
    wire        branch_cond;
    wire        branch_taken;
    wire        is_jal;

    wire        reg_dst;
    wire        alu_src;
    wire        mem_to_reg;
    wire        reg_write;
    wire        mem_read;
    wire        mem_write;
    wire        branch;
    wire        jump;
    wire [3:0]  alu_op;

    wire [3:0]  opcode;
    wire [2:0]  funct;
    wire [2:0]  rs;
    wire [2:0]  rt;
    wire [2:0]  rd;
    wire [5:0]  imm;
    wire [11:0] jump_addr;

    assign opcode    = instruction[15:12];
    assign rs        = instruction[11:9];
    assign rt        = instruction[8:6];
    assign rd        = instruction[5:3];
    assign funct     = instruction[2:0];
    assign imm       = instruction[5:0];
    assign jump_addr = instruction[11:0];
    assign is_jal    = (opcode == 4'b1011);

    program_counter pc (
        .clk      (clk),
        .rst      (rst),
        .pc_write (1'b1),
        .pc_in    (pc_next),
        .pc_out   (pc_out)
    );

    adder pc_add2 (
        .a   (pc_out),
        .b   (16'h0002),
        .sum (pc_plus2)
    );

    instruction_memory imem (
        .address     (pc_out),
        .instruction (instruction)
    );

    control_unit ctrl (
        .opcode     (opcode),
        .funct      (funct),
        .reg_dst    (reg_dst),
        .alu_src    (alu_src),
        .mem_to_reg (mem_to_reg),
        .reg_write  (reg_write),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .branch     (branch),
        .jump       (jump),
        .alu_op     (alu_op)
    );

    mux2to1_3 reg_dst_mux (
        .in0 (rt),
        .in1 (rd),
        .sel (reg_dst),
        .out (rd_or_rt)
    );

    // JAL saves return address (PC + 2) into $7 (3'b111)
    assign reg_dst_mux_out = is_jal ? 3'b111 : rd_or_rt;

    register_file rf (
        .clk        (clk),
        .rst        (rst),
        .reg_write  (reg_write),
        .read_reg1  (rs),
        .read_reg2  (rt),
        .write_reg  (reg_dst_mux_out),
        .write_data (reg_write_data),
        .read_data1 (read_data1),
        .read_data2 (read_data2)
    );

    sign_extend se (
        .imm_in  (imm),
        .imm_out (sign_ext_imm)
    );

    mux2to1_16 alu_src_mux (
        .in0 (read_data2),
        .in1 (sign_ext_imm),
        .sel (alu_src),
        .out (alu_in2)
    );

    alu alu_inst (
        .a        (read_data1),
        .b        (alu_in2),
        .alu_op   (alu_op),
        .result   (alu_result),
        .zero     (zero_flag),
        .negative (),
        .carry    (),
        .overflow ()
    );

    shift_left_2 sl2 (
        .in  (sign_ext_imm),
        .out (branch_offset)
    );

    adder branch_add (
        .a   (pc_plus2),
        .b   (branch_offset),
        .sum (pc_branch)
    );

    // BEQ (4'b1000) branches on zero_flag == 1; BNE (4'b1001) branches on zero_flag == 0
    assign branch_cond  = (opcode == 4'b1001) ? ~zero_flag : zero_flag;
    assign branch_taken = branch & branch_cond;

    mux2to1_16 pc_branch_mux (
        .in0 (pc_plus2),
        .in1 (pc_branch),
        .sel (branch_taken),
        .out (pc_jump)
    );

    assign pc_next = jump ? {pc_plus2[15:12], jump_addr} : pc_jump;

    data_memory dmem (
        .clk        (clk),
        .rst        (rst),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .address    (alu_result),
        .write_data (read_data2),
        .read_data  (mem_read_data)
    );

    mux2to1_16 mem_to_reg_mux (
        .in0 (alu_result),
        .in1 (mem_read_data),
        .sel (mem_to_reg),
        .out (wb_mux_data)
    );

    assign reg_write_data = is_jal ? pc_plus2 : wb_mux_data;
    assign write_data     = reg_write_data;
    assign write_reg      = reg_dst_mux_out;

endmodule
`default_nettype wire
