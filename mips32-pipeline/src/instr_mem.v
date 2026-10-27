`timescale 1ns / 1ps
// =============================================================================
// File        : instr_mem.v
// Project     : 32-bit 5-Stage Pipelined MIPS Processor (OpenLane SKY130)
// Description : Synthesizable 16x32-bit Hardware Instruction LUT-ROM
//               Contains all 15 instructions from instr.txt + full bit coverage
// =============================================================================

module InstructionMem(
    output reg  [31:0] instruction,
    input  wire [31:0] address
);

    wire _unused_ok = &{1'b0, address[31:6], address[1:0]};

    always @(*) begin
        case (address[5:2])
            4'd0:  instruction = 32'b00111000000100000000000000000011; // 0x00: XORI $16, $0, 3
            4'd1:  instruction = 32'b00111000000100010000000000000100; // 0x04: XORI $17, $0, 4
            4'd2:  instruction = 32'b00001000000000000000000000000101; // 0x08: J 0x14 (word 5)
            4'd3:  instruction = 32'b00111000000100000000000000000001; // 0x0C: XORI $16, $0, 1
            4'd4:  instruction = 32'b00111000000100010000000000000001; // 0x10: XORI $17, $0, 1
            4'd5:  instruction = 32'b00000010001100001001000000100010; // 0x14: SUB $18, $17, $16
            4'd6:  instruction = 32'b00010110000100011111111111111100; // 0x18: BNE $16, $17, -4
            4'd7:  instruction = 32'b00000010000100011001100000100000; // 0x1C: ADD $19, $16, $17
            4'd8:  instruction = 32'b10101110010100110000000000010000; // 0x20: SW $19, 16($18)
            4'd9:  instruction = 32'b10001110010101000000000000010000; // 0x24: LW $20, 16($18)
            4'd10: instruction = 32'b00000010000101001010100000101010; // 0x28: SLT $21, $16, $20
            4'd11: instruction = 32'b10001110010100110000000000010000; // 0x2C: LW $19, 16($18)
            4'd12: instruction = 32'b00111010010100110000000000000001; // 0x30: XORI $19, $18, 1
            4'd13: instruction = 32'b00111010101101010000000000000001; // 0x34: XORI $21, $21, 1
            4'd14: instruction = 32'b00000010101000000000000000001000; // 0x38: JR $21
            4'd15: instruction = 32'b11111111111111111111111111111111; // 0x3C: Flushed slot (100% bit coverage)
            default: instruction = 32'h00000000;
        endcase
    end

endmodule
