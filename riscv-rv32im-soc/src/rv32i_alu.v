// =============================================================================
// File        : rv32i_alu.v
// Project     : RV32IM + Zicsr 5-Stage Pipelined SoC (OpenLane SKY130 Target)
// Description : 32-bit Combinational ALU supporting all RV32I base operations
// =============================================================================
`default_nettype none
`include "rv32i_defs.vh"

module rv32i_alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_op,
    output reg  [31:0] result
);

    wire signed [31:0] a_signed = a;
    wire signed [31:0] b_signed = b;

    always @(*) begin
        case (alu_op)
            `ALU_ADD:    result = a + b;
            `ALU_SUB:    result = a - b;
            `ALU_SLL:    result = a << b[4:0];
            `ALU_SLT:    result = (a_signed < b_signed) ? 32'd1 : 32'd0;
            `ALU_SLTU:   result = (a < b) ? 32'd1 : 32'd0;
            `ALU_XOR:    result = a ^ b;
            `ALU_SRL:    result = a >> b[4:0];
            `ALU_SRA:    result = a_signed >>> b[4:0];
            `ALU_OR:     result = a | b;
            `ALU_AND:    result = a & b;
            `ALU_PASS_B: result = b;
            default:     result = 32'h0000_0000;
        endcase
    end

endmodule
`default_nettype wire
