`timescale 1ns / 1ps
// =============================================================================
// File        : instruction_memory.v
// Project     : 16-bit MIPS Single-Cycle Processor (OpenLane SKY130 Target)
// Description : Synthesizable 32x16-bit Hardware Instruction LUT-ROM
//               (Prevents Yosys from optimizing away the processor when
//                $readmemh is ignored in ASIC synthesis)
// =============================================================================
`default_nettype none

module instruction_memory (
    input  wire [15:0] address,
    output reg  [15:0] instruction
);

    wire _unused_ok = &{1'b0, address[15:6], address[0]};

    always @(*) begin
        case (address[5:1])
            5'd0:  instruction = 16'h104A; // 0x00: ADDI $1, $0, 10      -> $1 = 10 (0x000A)
            5'd1:  instruction = 16'h10BB; // 0x02: ADDI $2, $0, -5      -> $2 = -5 (0xFFFB)
            5'd2:  instruction = 16'h0298; // 0x04: ADD  $3, $1, $2      -> $3 = 5  (0x0005)
            5'd3:  instruction = 16'h02A1; // 0x06: SUB  $4, $1, $2      -> $4 = 15 (0x000F)
            5'd4:  instruction = 16'h032A; // 0x08: AND  $5, $1, $4      -> $5 = 10 (0x000A)
            5'd5:  instruction = 16'h02F3; // 0x0A: OR   $6, $1, $3      -> $6 = 15 (0x000F)
            5'd6:  instruction = 16'h033C; // 0x0C: XOR  $7, $1, $4      -> $7 = 5  (0x0005)
            5'd7:  instruction = 16'h046E; // 0x0E: SLT  $5, $2, $1      -> $5 = 1  (0x0001)
            5'd8:  instruction = 16'h0777; // 0x10: SLL  $6, $3, $5      -> $6 = 10 (0x000A)
            5'd9:  instruction = 16'h29CC; // 0x12: ANDI $7, $4, 12      -> $7 = 12 (0x000C)
            5'd10: instruction = 16'h3FC3; // 0x14: ORI  $7, $7, 3       -> $7 = 15 (0x000F)
            5'd11: instruction = 16'h7104; // 0x16: SW   $4, 4($0)       -> DMEM[2] = 0x000F
            5'd12: instruction = 16'h6144; // 0x18: LW   $5, 4($0)       -> $5 = 0x000F
            5'd13: instruction = 16'h8941; // 0x1A: BEQ  $4, $5, +1      -> Taken to 0x0020
            5'd14: instruction = 16'h115F; // 0x1C: ADDI $5, $0, 31      -> Skipped
            5'd15: instruction = 16'h119F; // 0x1E: ADDI $6, $0, 31      -> Skipped
            5'd16: instruction = 16'h9281; // 0x20: BNE  $1, $2, +1      -> Taken to 0x0026
            5'd17: instruction = 16'h1040; // 0x22: ADDI $1, $0, 0       -> Skipped
            5'd18: instruction = 16'h1080; // 0x24: ADDI $2, $0, 0       -> Skipped
            5'd19: instruction = 16'hC195; // 0x26: LUI  $6, 0x15        -> $6 = 0x1500
            5'd20: instruction = 16'hB02E; // 0x28: JAL  0x02E           -> $7 = 0x002A, PC = 0x002E
            5'd21: instruction = 16'h1180; // 0x2A: ADDI $6, $0, 0       -> Skipped
            5'd22: instruction = 16'h1180; // 0x2C: ADDI $6, $0, 0       -> Skipped
            5'd23: instruction = 16'h0718; // 0x2E: ADD  $3, $3, $4      -> $3 = 20 (0x0014)
            5'd24: instruction = 16'hA030; // 0x30: J    0x030           -> Halt loop
            default: instruction = 16'h0000;
        endcase
    end

endmodule
`default_nettype wire
