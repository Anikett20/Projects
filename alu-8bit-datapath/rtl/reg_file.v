// ============================================================
//  8-Bit SoC Register File
//  File    : reg_file.v
//
//  - 8 general-purpose 8-bit registers (R0–R7)
//  - Synchronous WRITE  (on rising clock edge)
//  - Asynchronous READ  (combinational, no delay)
//  - Two simultaneous read ports (for ALU operands A and B)
//  - One write port (for ALU result)
//  - R0 is hardwired to 0x00 (cannot be written — common convention)
// ============================================================

module reg_file (
    input             clk,          // System clock
    input             reset,        // Active-high synchronous reset

    // ── Write Port (from ALU result) ──────────────────────────
    input             write_en,     // Write enable (from Control Unit)
    input      [2:0]  write_addr,   // Destination register (R0–R7)
    input      [7:0]  write_data,   // Data to write (ALU result)

    // ── Read Port A (operand A → ALU) ─────────────────────────
    input      [2:0]  read_addr_a,  // Source register for A
    output     [7:0]  read_data_a,  // Data out → alu.a

    // ── Read Port B (operand B → ALU) ─────────────────────────
    input      [2:0]  read_addr_b,  // Source register for B
    output     [7:0]  read_data_b   // Data out → alu.b
);

    // ── Register Array ────────────────────────────────────────
    reg [7:0] registers [0:7];      // 8 registers × 8 bits

    integer i;

    // ── Synchronous Write + Reset ─────────────────────────────
    always @(posedge clk) begin
        if (reset) begin
            // Clear all registers on reset
            for (i = 0; i < 8; i = i + 1)
                registers[i] <= 8'b0;
        end else if (write_en && write_addr != 3'b000) begin
            // R0 is read-only (zero register) — writes to R0 ignored
            registers[write_addr] <= write_data;
        end
    end

    // ── Asynchronous Read (combinational) ────────────────────
    assign read_data_a = (read_addr_a == 3'b000) ? 8'b0 : registers[read_addr_a];
    assign read_data_b = (read_addr_b == 3'b000) ? 8'b0 : registers[read_addr_b];

endmodule
