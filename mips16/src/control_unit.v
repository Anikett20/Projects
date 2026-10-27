`timescale 1ns / 1ps
`default_nettype none

module control_unit (
    input  wire [3:0]  opcode,
    input  wire [2:0]  funct,
    output reg         reg_dst,
    output reg         alu_src,
    output reg         mem_to_reg,
    output reg         reg_write,
    output reg         mem_read,
    output reg         mem_write,
    output reg         branch,
    output reg         jump,
    output reg [3:0]   alu_op
);

    localparam OP_RTYPE   = 4'b0000;
    localparam OP_ADDI    = 4'b0001;
    localparam OP_ANDI    = 4'b0010;
    localparam OP_ORI     = 4'b0011;
    localparam OP_XORI    = 4'b0100;
    localparam OP_SLTI    = 4'b0101;
    localparam OP_LW      = 4'b0110;
    localparam OP_SW      = 4'b0111;
    localparam OP_BEQ     = 4'b1000;
    localparam OP_BNE     = 4'b1001;
    localparam OP_J       = 4'b1010;
    localparam OP_JAL     = 4'b1011;
    localparam OP_LUI     = 4'b1100;

    localparam FUNC_ADD   = 3'b000;
    localparam FUNC_SUB   = 3'b001;
    localparam FUNC_AND   = 3'b010;
    localparam FUNC_OR    = 3'b011;
    localparam FUNC_XOR   = 3'b100;
    localparam FUNC_NOR   = 3'b101;
    localparam FUNC_SLT   = 3'b110;
    localparam FUNC_SHIFT = 3'b111;

    always @(*) begin
        reg_dst    = 1'b0;
        alu_src    = 1'b0;
        mem_to_reg = 1'b0;
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_op     = 4'b0000;

        case (opcode)
            OP_RTYPE: begin
                reg_dst   = 1'b1;
                reg_write = 1'b1;
                case (funct)
                    FUNC_ADD:   alu_op = 4'b0000;
                    FUNC_SUB:   alu_op = 4'b0001;
                    FUNC_AND:   alu_op = 4'b0010;
                    FUNC_OR:    alu_op = 4'b0011;
                    FUNC_XOR:   alu_op = 4'b0100;
                    FUNC_NOR:   alu_op = 4'b0101;
                    FUNC_SLT:   alu_op = 4'b0110;
                    FUNC_SHIFT: alu_op = 4'b0111;
                    default:    alu_op = 4'b0000;
                endcase
            end
            OP_ADDI: begin
                alu_src   = 1'b1;
                reg_write = 1'b1;
                alu_op    = 4'b0000;
            end
            OP_ANDI: begin
                alu_src   = 1'b1;
                reg_write = 1'b1;
                alu_op    = 4'b0010;
            end
            OP_ORI: begin
                alu_src   = 1'b1;
                reg_write = 1'b1;
                alu_op    = 4'b0011;
            end
            OP_XORI: begin
                alu_src   = 1'b1;
                reg_write = 1'b1;
                alu_op    = 4'b0100;
            end
            OP_SLTI: begin
                alu_src   = 1'b1;
                reg_write = 1'b1;
                alu_op    = 4'b0110;
            end
            OP_LW: begin
                alu_src    = 1'b1;
                mem_to_reg = 1'b1;
                reg_write  = 1'b1;
                mem_read   = 1'b1;
                alu_op     = 4'b0000;
            end
            OP_SW: begin
                alu_src   = 1'b1;
                mem_write = 1'b1;
                alu_op    = 4'b0000;
            end
            OP_BEQ: begin
                branch = 1'b1;
                alu_op = 4'b0001;
            end
            OP_BNE: begin
                branch = 1'b1;
                alu_op = 4'b0001;
            end
            OP_J: begin
                jump = 1'b1;
            end
            OP_JAL: begin
                jump      = 1'b1;
                reg_write = 1'b1;
            end
            OP_LUI: begin
                alu_src   = 1'b1;
                reg_write = 1'b1;
                alu_op    = 4'b1010;
            end
            default: begin
            end
        endcase
    end

endmodule
`default_nettype wire
