// =============================================================================
// File        : rv32i_decoder.v
// Project     : RV32IM + Zicsr 5-Stage Pipelined SoC (OpenLane SKY130 Target)
// Description : Full RV32IM + Zicsr + Machine Trap Instruction Decoder
// =============================================================================
`default_nettype none
`include "rv32i_defs.vh"

module rv32i_decoder (
    input  wire [31:0] inst,
    output reg         reg_we,
    output reg  [2:0]  imm_sel,
    output reg         alu_src_a_pc,
    output reg         alu_src_b_imm,
    output reg  [3:0]  alu_op,
    output reg         is_mdu,
    output reg         is_branch,
    output reg         is_jal,
    output reg         is_jalr,
    output reg         mem_read,
    output reg         mem_write,
    output reg  [1:0]  wb_sel,
    output reg         csr_en,
    output reg         is_ecall,
    output reg         is_ebreak,
    output reg         is_mret,
    output reg         is_wfi,
    output reg         illegal_inst
);

    wire [6:0] opcode = inst[6:0];
    wire [2:0] funct3 = inst[14:12];
    wire [6:0] funct7 = inst[31:25];
    wire [11:0] imm12 = inst[31:20];

    always @(*) begin
        reg_we        = 1'b0;
        imm_sel       = `IMM_I;
        alu_src_a_pc  = 1'b0;
        alu_src_b_imm = 1'b0;
        alu_op        = `ALU_ADD;
        is_mdu        = 1'b0;
        is_branch     = 1'b0;
        is_jal        = 1'b0;
        is_jalr       = 1'b0;
        mem_read      = 1'b0;
        mem_write     = 1'b0;
        wb_sel        = `WB_ALU;
        csr_en        = 1'b0;
        is_ecall      = 1'b0;
        is_ebreak     = 1'b0;
        is_mret       = 1'b0;
        is_wfi        = 1'b0;
        illegal_inst  = 1'b0;

        case (opcode)
            `OPCODE_LUI: begin
                reg_we        = 1'b1;
                imm_sel       = `IMM_U;
                alu_src_b_imm = 1'b1;
                alu_op        = `ALU_PASS_B;
                wb_sel        = `WB_ALU;
            end

            `OPCODE_AUIPC: begin
                reg_we        = 1'b1;
                imm_sel       = `IMM_U;
                alu_src_a_pc  = 1'b1;
                alu_src_b_imm = 1'b1;
                alu_op        = `ALU_ADD;
                wb_sel        = `WB_ALU;
            end

            `OPCODE_JAL: begin
                reg_we        = 1'b1;
                imm_sel       = `IMM_J;
                alu_src_a_pc  = 1'b1;
                alu_src_b_imm = 1'b1;
                alu_op        = `ALU_ADD;
                is_jal        = 1'b1;
                wb_sel        = `WB_PC4;
            end

            `OPCODE_JALR: begin
                reg_we        = 1'b1;
                imm_sel       = `IMM_I;
                alu_src_a_pc  = 1'b0;
                alu_src_b_imm = 1'b1;
                alu_op        = `ALU_ADD;
                is_jalr       = 1'b1;
                wb_sel        = `WB_PC4;
            end

            `OPCODE_BRANCH: begin
                imm_sel       = `IMM_B;
                alu_src_a_pc  = 1'b1;
                alu_src_b_imm = 1'b1;
                alu_op        = `ALU_ADD;
                is_branch     = 1'b1;
            end

            `OPCODE_LOAD: begin
                reg_we        = 1'b1;
                imm_sel       = `IMM_I;
                alu_src_b_imm = 1'b1;
                alu_op        = `ALU_ADD;
                mem_read      = 1'b1;
                wb_sel        = `WB_MEM;
                // Allow LB(000), LH(001), LW(010), LBU(100), LHU(101)
                if (funct3 == 3'b011 || funct3 > 3'b101)
                    illegal_inst = 1'b1;
            end

            `OPCODE_STORE: begin
                imm_sel       = `IMM_S;
                alu_src_b_imm = 1'b1;
                alu_op        = `ALU_ADD;
                mem_write     = 1'b1;
                if (funct3 > 3'b010)
                    illegal_inst = 1'b1;
            end

            `OPCODE_OP_IMM: begin
                reg_we        = 1'b1;
                imm_sel       = `IMM_I;
                alu_src_b_imm = 1'b1;
                wb_sel        = `WB_ALU;
                case (funct3)
                    3'b000: alu_op = `ALU_ADD;
                    3'b010: alu_op = `ALU_SLT;
                    3'b011: alu_op = `ALU_SLTU;
                    3'b100: alu_op = `ALU_XOR;
                    3'b110: alu_op = `ALU_OR;
                    3'b111: alu_op = `ALU_AND;
                    3'b001: alu_op = `ALU_SLL;
                    3'b101: alu_op = (funct7[5]) ? `ALU_SRA : `ALU_SRL;
                endcase
            end

            `OPCODE_OP: begin
                reg_we        = 1'b1;
                alu_src_b_imm = 1'b0;
                wb_sel        = `WB_ALU;
                if (funct7 == 7'b0000001) begin
                    is_mdu = 1'b1;
                end else begin
                    case (funct3)
                        3'b000: alu_op = (funct7[5]) ? `ALU_SUB : `ALU_ADD;
                        3'b001: alu_op = `ALU_SLL;
                        3'b010: alu_op = `ALU_SLT;
                        3'b011: alu_op = `ALU_SLTU;
                        3'b100: alu_op = `ALU_XOR;
                        3'b101: alu_op = (funct7[5]) ? `ALU_SRA : `ALU_SRL;
                        3'b110: alu_op = `ALU_OR;
                        3'b111: alu_op = `ALU_AND;
                    endcase
                end
            end

            `OPCODE_MISC_MEM: begin
                reg_we = 1'b0;
            end

            `OPCODE_SYSTEM: begin
                if (funct3 == 3'b000) begin
                    case (imm12)
                        12'h000: is_ecall  = 1'b1;
                        12'h001: is_ebreak = 1'b1;
                        12'h302: is_mret   = 1'b1;
                        12'h105: is_wfi    = 1'b1;  // WFI instruction
                        default: illegal_inst = 1'b1;
                    endcase
                end else if (funct3 != 3'b100) begin
                    // CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CSRRCI
                    reg_we = 1'b1;
                    csr_en = 1'b1;
                    wb_sel = `WB_CSR;
                end else begin
                    illegal_inst = 1'b1;
                end
            end

            default: begin
                illegal_inst = 1'b1;
            end
        endcase
    end

endmodule
`default_nettype wire
