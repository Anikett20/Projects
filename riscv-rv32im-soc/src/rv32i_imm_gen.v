// =============================================================================
// File        : rv32i_imm_gen.v
// Project     : RV32IM + Zicsr 5-Stage Pipelined SoC (OpenLane SKY130 Target)
// Description : Sign-extended 32-bit Immediate Generator (I, S, B, U, J)
// =============================================================================
`default_nettype none
`include "rv32i_defs.vh"

module rv32i_imm_gen (
    input  wire [31:0] inst,
    input  wire [2:0]  imm_sel,
    output reg  [31:0] imm_out
);

    always @(*) begin
        case (imm_sel)
            `IMM_I: imm_out = {{20{inst[31]}}, inst[31:20]};
            `IMM_S: imm_out = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            `IMM_B: imm_out = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
            `IMM_U: imm_out = {inst[31:12], 12'b0};
            `IMM_J: imm_out = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
            default: imm_out = 32'h0000_0000;
        endcase
    end

endmodule
`default_nettype wire
