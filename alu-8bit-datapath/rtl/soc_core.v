// ============================================================
//  SoC Top-Level Wrapper  —  ALU + Register File
//  File    : soc_core.v
//
//  This is the "brain" of the SoC:
//    1. Control Unit supplies opcode + register addresses
//    2. Register File reads two operands (A, B) and feeds the ALU
//    3. ALU computes the result + flags
//    4. Result is written back to the Register File
// ============================================================

module soc_core (
    input        clk,           // System clock
    input        reset,         // Active-high synchronous reset

    // ── Control Unit Interface (will be its own module next) ──
    input [2:0]  opcode,        // ALU operation
    input [2:0]  reg_src_a,     // Register address for operand A
    input [2:0]  reg_src_b,     // Register address for operand B
    input [2:0]  reg_dst,       // Destination register for result
    input        write_en,      // Write-back enable

    // ── Status Flag Outputs (visible to Control Unit) ─────────
    output       zero_flag,     // ALU result == 0
    output       carry_flag     // Carry / borrow / shift out
);

    // ── Internal Wires ────────────────────────────────────────
    wire [7:0] operand_a;       // Reg File → ALU
    wire [7:0] operand_b;       // Reg File → ALU
    wire [7:0] alu_result;      // ALU → Reg File

    // ── Register File ─────────────────────────────────────────
    reg_file u_reg_file (
        .clk         (clk),
        .reset       (reset),

        // Write-back from ALU
        .write_en    (write_en),
        .write_addr  (reg_dst),
        .write_data  (alu_result),

        // Read two operands
        .read_addr_a (reg_src_a),
        .read_data_a (operand_a),
        .read_addr_b (reg_src_b),
        .read_data_b (operand_b)
    );

    // ── ALU ───────────────────────────────────────────────────
    alu u_alu (
        .a          (operand_a),
        .b          (operand_b),
        .opcode     (opcode),
        .result     (alu_result),
        .zero_flag  (zero_flag),
        .carry_flag (carry_flag)
    );

endmodule
