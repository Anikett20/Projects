// ============================================================
//  Control Unit  —  SoC Brain
//  File    : control_unit.v
//
//  Decodes a 16-bit instruction word and drives all control
//  signals for the Register File and ALU.
//
//  ── Instruction Format (16-bit) ──────────────────────────
//
//   [15:12] [11:9]  [8:6]   [5:3]   [2:0]
//   OPCODE  RD      RS_A    RS_B    (reserved)
//
//   OPCODE (4-bit):
//     0000 = ADD   rd = ra + rb
//     0001 = SUB   rd = ra - rb
//     0010 = AND   rd = ra & rb
//     0011 = OR    rd = ra | rb
//     0100 = XOR   rd = ra ^ rb
//     0101 = NOT   rd = ~ra
//     0110 = SHL   rd = ra << 1
//     0111 = SHR   rd = ra >> 1
//     1000 = LOAD  rd = immediate (lower 8 bits of instr)
//     1001 = MOV   rd = ra
//     1010 = NOP   no operation
//     1011 = HLT   halt (freeze outputs)
//
// ============================================================

module control_unit (
    input             clk,          // System clock
    input             reset,        // Active-high synchronous reset

    // ── Instruction Input ─────────────────────────────────
    input      [15:0] instruction,  // 16-bit instruction word

    // ── Status Flags (from ALU) ───────────────────────────
    input             zero_flag,    // ALU result == 0
    input             carry_flag,   // Carry / borrow out

    // ── Control Outputs → Register File + ALU ────────────
    output reg [2:0]  opcode,       // 3-bit ALU opcode
    output reg [2:0]  reg_src_a,    // Register address A
    output reg [2:0]  reg_src_b,    // Register address B
    output reg [2:0]  reg_dst,      // Destination register
    output reg        write_en,     // Register file write enable

    // ── Special Outputs ───────────────────────────────────
    output reg [7:0]  imm_data,     // Immediate value (LOAD)
    output reg        imm_sel,      // 1 = use imm_data instead of ALU result
    output reg        halt          // 1 = processor halted
);

    // ── Instruction Field Aliases ─────────────────────────
    wire [3:0] instr_op  = instruction[15:12];
    wire [2:0] instr_rd  = instruction[11:9];
    wire [2:0] instr_ra  = instruction[8:6];
    wire [2:0] instr_rb  = instruction[5:3];
    wire [7:0] instr_imm = instruction[7:0];   // for LOAD

    // ── Instruction Opcodes ───────────────────────────────
    localparam I_ADD  = 4'b0000;
    localparam I_SUB  = 4'b0001;
    localparam I_AND  = 4'b0010;
    localparam I_OR   = 4'b0011;
    localparam I_XOR  = 4'b0100;
    localparam I_NOT  = 4'b0101;
    localparam I_SHL  = 4'b0110;
    localparam I_SHR  = 4'b0111;
    localparam I_LOAD = 4'b1000;
    localparam I_MOV  = 4'b1001;
    localparam I_NOP  = 4'b1010;
    localparam I_HLT  = 4'b1011;

    // ── ALU Opcode Map (3-bit) ────────────────────────────
    localparam ALU_ADD = 3'b000;
    localparam ALU_SUB = 3'b001;
    localparam ALU_AND = 3'b010;
    localparam ALU_OR  = 3'b011;
    localparam ALU_XOR = 3'b100;
    localparam ALU_NOT = 3'b101;
    localparam ALU_SHL = 3'b110;
    localparam ALU_SHR = 3'b111;

    // ── Combinational Decode ──────────────────────────────
    always @(*) begin
        // Safe defaults — prevents latches
        opcode    = ALU_ADD;
        reg_src_a = instr_ra;
        reg_src_b = instr_rb;
        reg_dst   = instr_rd;
        write_en  = 1'b0;
        imm_data  = 8'b0;
        imm_sel   = 1'b0;
        halt      = 1'b0;

        if (!halt) begin
            case (instr_op)

                I_ADD: begin
                    opcode   = ALU_ADD;
                    write_en = 1'b1;
                end

                I_SUB: begin
                    opcode   = ALU_SUB;
                    write_en = 1'b1;
                end

                I_AND: begin
                    opcode   = ALU_AND;
                    write_en = 1'b1;
                end

                I_OR: begin
                    opcode   = ALU_OR;
                    write_en = 1'b1;
                end

                I_XOR: begin
                    opcode   = ALU_XOR;
                    write_en = 1'b1;
                end

                I_NOT: begin
                    opcode    = ALU_NOT;
                    reg_src_a = instr_ra;
                    write_en  = 1'b1;
                end

                I_SHL: begin
                    opcode    = ALU_SHL;
                    reg_src_a = instr_ra;
                    write_en  = 1'b1;
                end

                I_SHR: begin
                    opcode    = ALU_SHR;
                    reg_src_a = instr_ra;
                    write_en  = 1'b1;
                end

                I_LOAD: begin
                    // Load 8-bit immediate into rd
                    // ALU not used — imm_sel bypasses it
                    opcode   = ALU_ADD;   // don't care
                    reg_dst  = instr_rd;
                    imm_data = instr_imm;
                    imm_sel  = 1'b1;
                    write_en = 1'b1;
                end

                I_MOV: begin
                    // Copy ra → rd through ALU (NOT ra, NOT again = ra... use OR ra,R0)
                    opcode    = ALU_OR;
                    reg_src_a = instr_ra;
                    reg_src_b = 3'b000;  // R0 = 0, so OR a,0 = a
                    write_en  = 1'b1;
                end

                I_NOP: begin
                    write_en = 1'b0;     // Do nothing
                end

                I_HLT: begin
                    halt     = 1'b1;
                    write_en = 1'b0;
                end

                default: begin
                    write_en = 1'b0;     // Unknown opcode = NOP
                end

            endcase
        end
    end

endmodule
