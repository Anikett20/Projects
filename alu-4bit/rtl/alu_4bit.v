`timescale 1ns / 1ps

module alu_4bit (
    input wire clk,
    input wire rst,
    input wire [3:0] a,
    input wire [3:0] b,
    input wire [2:0] opcode,
    output reg [3:0] result,
    output reg carry_out,
    output reg zero
);

    // 5-bit wire to catch carry/borrow operations
    reg [4:0] temp_result;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result     <= 4'b0000;
            carry_out  <= 1'b0;
            zero       <= 1'b0;
            temp_result = 5'b00000;
        end else begin
            case (opcode)
                3'b000: temp_result = a + b;           // ADD
                3'b001: temp_result = a - b;           // SUB
                3'b010: temp_result = {1'b0, a & b};   // AND
                3'b011: temp_result = {1'b0, a | b};   // OR
                3'b100: temp_result = {1'b0, a ^ b};   // XOR
                3'b101: temp_result = {1'b0, ~a};      // NOT A
                3'b110: temp_result = {1'b0, a << 1};  // Logical Shift Left A
                3'b111: temp_result = {1'b0, a >> 1};  // Logical Shift Right A
                default: temp_result = 5'b00000;
            endcase

            // Assign outputs based on the 5-bit calculation
            result    <= temp_result[3:0];
            carry_out <= temp_result[4];
            
            // Zero flag logic
            if (temp_result[3:0] == 4'b0000)
                zero <= 1'b1;
            else
                zero <= 1'b0;
        end
    end

endmodule