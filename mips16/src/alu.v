`timescale 1ns / 1ps
`default_nettype none

module alu (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire [3:0]  alu_op,
    output reg  [15:0] result,
    output wire        zero,
    output wire        negative,
    output wire        carry,
    output wire        overflow
);

    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_NOR  = 4'b0101;
    localparam ALU_SLT  = 4'b0110;
    localparam ALU_SLL  = 4'b0111;
    localparam ALU_SRL  = 4'b1000;
    localparam ALU_SRA  = 4'b1001;
    localparam ALU_LUI  = 4'b1010;

    reg [16:0] temp_result;
    reg        temp_carry;
    reg        temp_overflow;

    always @(*) begin
        result        = 16'h0000;
        temp_result   = 17'h00000;
        temp_carry    = 1'b0;
        temp_overflow = 1'b0;

        case (alu_op)
            ALU_ADD: begin
                temp_result   = a + b;
                result        = temp_result[15:0];
                temp_carry    = temp_result[16];
                temp_overflow = (a[15] == b[15]) && (result[15] != a[15]);
            end
            ALU_SUB: begin
                temp_result   = a - b;
                result        = temp_result[15:0];
                temp_carry    = temp_result[16];
                temp_overflow = (a[15] != b[15]) && (result[15] != a[15]);
            end
            ALU_AND: begin
                result = a & b;
            end
            ALU_OR: begin
                result = a | b;
            end
            ALU_XOR: begin
                result = a ^ b;
            end
            ALU_NOR: begin
                result = ~(a | b);
            end
            ALU_SLT: begin
                result = ($signed(a) < $signed(b)) ? 16'h0001 : 16'h0000;
            end
            ALU_SLL: begin
                result = a << b[3:0];
            end
            ALU_SRL: begin
                result = a >> b[3:0];
            end
            ALU_SRA: begin
                result = $signed(a) >>> b[3:0];
            end
            ALU_LUI: begin
                result = b << 8;
            end
            default: begin
                result = 16'h0000;
            end
        endcase
    end

    assign zero     = (result == 16'h0000);
    assign negative = result[15];
    assign carry    = temp_carry;
    assign overflow = temp_overflow;

endmodule
`default_nettype wire
