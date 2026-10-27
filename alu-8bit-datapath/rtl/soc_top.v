// ============================================================
//  Full SoC Top-Level
//  File    : soc_top.v
//
//  Integrates:
//    1. Control Unit  — decodes 16-bit instructions
//    2. Register File — stores 8 × 8-bit registers
//    3. ALU           — executes arithmetic/logic operations
//
//  Data flow:
//    instruction → control_unit
//                      ↓  (opcode, reg addresses, write_en)
//              reg_file (read A, B)
//                      ↓  (operand_a, operand_b)
//                    alu  (compute)
//                      ↓  (result, flags)
//              reg_file (write back)   ← control_unit (write_en)
//                      ↑
//              control_unit ← flags (zero, carry)
// ============================================================

module soc_top (
    input        clk,           // System clock
    input        reset,         // Active-high synchronous reset
    input [15:0] instruction,   // 16-bit instruction (from Program Memory)

    // ── Observable outputs for testbench / debug ──────────
    output [7:0] result,        // ALU result
    output       zero_flag,     // Zero status flag
    output       carry_flag,    // Carry status flag
    output       halt           // Processor halted
);

    // ── Internal control signals ──────────────────────────
    wire [2:0] opcode;
    wire [2:0] reg_src_a, reg_src_b, reg_dst;
    wire       write_en;
    wire       imm_sel;
    wire [7:0] imm_data;

    // ── Internal data wires ───────────────────────────────
    wire [7:0] operand_a, operand_b;
    wire [7:0] alu_result;

    // Write-back data: immediate (LOAD) or ALU result
    wire [7:0] wb_data = imm_sel ? imm_data : alu_result;

    // ── 1. Control Unit ───────────────────────────────────
    control_unit u_cu (
        .clk         (clk),
        .reset       (reset),
        .instruction (instruction),
        .zero_flag   (zero_flag),
        .carry_flag  (carry_flag),
        .opcode      (opcode),
        .reg_src_a   (reg_src_a),
        .reg_src_b   (reg_src_b),
        .reg_dst     (reg_dst),
        .write_en    (write_en),
        .imm_data    (imm_data),
        .imm_sel     (imm_sel),
        .halt        (halt)
    );

    // ── 2. Register File ──────────────────────────────────
    reg_file u_rf (
        .clk         (clk),
        .reset       (reset),
        .write_en    (write_en),
        .write_addr  (reg_dst),
        .write_data  (wb_data),       // ALU result OR immediate
        .read_addr_a (reg_src_a),
        .read_data_a (operand_a),
        .read_addr_b (reg_src_b),
        .read_data_b (operand_b)
    );

    // ── 3. ALU ────────────────────────────────────────────
    alu u_alu (
        .a          (operand_a),
        .b          (operand_b),
        .opcode     (opcode),
        .result     (alu_result),
        .zero_flag  (zero_flag),
        .carry_flag (carry_flag)
    );

    assign result = wb_data;

endmodule
