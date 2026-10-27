// ============================================================
//  8-Bit SoC-Ready ALU
//  File    : alu.v
//  Inputs  : a, b (from Register File), opcode (from Control Unit)
//  Outputs : result (to Register File), zero_flag, carry_flag
// ============================================================

module alu (
    input  [7:0] a,           // 8-bit Data Input A (From Reg File)
    input  [7:0] b,           // 8-bit Data Input B (From Reg File)
    input  [2:0] opcode,      // 3-bit Instruction  (From Control Unit)

    output reg [7:0] result,  // 8-bit Data Output  (Back to Reg File)
    output zero_flag,         // 1 if result == 0
    output carry_flag         // Carry / Borrow out
);

    // ── Internal 9-bit wire to capture carry ──────────────────
    reg [8:0] full_result;    // bit[8] = carry/borrow

    // ── Opcode Definitions ───────────────────────────────────
    localparam ADD  = 3'b000; // result = a + b
    localparam SUB  = 3'b001; // result = a - b
    localparam AND  = 3'b010; // result = a & b
    localparam OR   = 3'b011; // result = a | b
    localparam XOR  = 3'b100; // result = a ^ b
    localparam NOT  = 3'b101; // result = ~a
    localparam SHL  = 3'b110; // result = a << 1  (logical shift left)
    localparam SHR  = 3'b111; // result = a >> 1  (logical shift right)

    // ── Purely Combinational Logic ────────────────────────────
    always @(*) begin
        full_result = 9'b0;   // default – avoids latches

        case (opcode)
            ADD : full_result = {1'b0, a} + {1'b0, b};
            SUB : full_result = {1'b0, a} - {1'b0, b};
            AND : full_result = {1'b0, a  & b};
            OR  : full_result = {1'b0, a  | b};
            XOR : full_result = {1'b0, a  ^ b};
            NOT : full_result = {1'b0, ~a};
            SHL : full_result = {a[7], a << 1};   // MSB captured as carry
            SHR : full_result = {a[0], a >> 1};   // LSB captured as carry
            default: full_result = 9'b0;
        endcase

        result = full_result[7:0];
    end

    // ── Status Flags (continuous assignment) ─────────────────
    assign zero_flag  = (result == 8'b0);   // HIGH when result is zero
    assign carry_flag = full_result[8];     // Carry out / borrow / shifted bit

endmodule
