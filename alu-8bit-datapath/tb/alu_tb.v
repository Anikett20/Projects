// ============================================================
//  Testbench for 8-Bit SoC-Ready ALU
//  File    : alu_tb.v
//  Sim     : iverilog alu_tb.v alu.v -o alu_sim && vvp alu_sim
// ============================================================

`timescale 1ns/1ps

module alu_tb;

    // ── DUT Signals ──────────────────────────────────────────
    reg  [7:0] a, b;
    reg  [2:0] opcode;
    wire [7:0] result;
    wire       zero_flag, carry_flag;

    // ── Instantiate DUT ──────────────────────────────────────
    alu dut (
        .a          (a),
        .b          (b),
        .opcode     (opcode),
        .result     (result),
        .zero_flag  (zero_flag),
        .carry_flag (carry_flag)
    );

    // ── Task: print one test row ──────────────────────────────
    task show;
        input [47:0] op_name;   // 6-char ASCII label
        begin
            $display("| %-5s | A=0x%02h | B=0x%02h | Result=0x%02h | Zero=%b | Carry=%b |",
                     op_name, a, b, result, zero_flag, carry_flag);
        end
    endtask

    // ── Stimulus ─────────────────────────────────────────────
    initial begin
        $display("============================================================");
        $display("           8-Bit ALU SoC-Ready – Test Results               ");
        $display("============================================================");

        // ---- ADD ------------------------------------------------
        a = 8'h1F; b = 8'h01; opcode = 3'b000; #10; show("ADD  ");
        a = 8'hFF; b = 8'h01; opcode = 3'b000; #10; show("ADD  "); // carry out

        // ---- SUB ------------------------------------------------
        a = 8'h10; b = 8'h05; opcode = 3'b001; #10; show("SUB  ");
        a = 8'h00; b = 8'h01; opcode = 3'b001; #10; show("SUB  "); // borrow

        // ---- AND ------------------------------------------------
        a = 8'hAA; b = 8'hF0; opcode = 3'b010; #10; show("AND  ");

        // ---- OR -------------------------------------------------
        a = 8'hAA; b = 8'h55; opcode = 3'b011; #10; show("OR   ");

        // ---- XOR ------------------------------------------------
        a = 8'hFF; b = 8'hFF; opcode = 3'b100; #10; show("XOR  "); // zero flag

        // ---- NOT ------------------------------------------------
        a = 8'hAA; b = 8'hXX; opcode = 3'b101; #10; show("NOT  ");

        // ---- SHL ------------------------------------------------
        a = 8'h81; b = 8'hXX; opcode = 3'b110; #10; show("SHL  "); // carry=MSB

        // ---- SHR ------------------------------------------------
        a = 8'h81; b = 8'hXX; opcode = 3'b111; #10; show("SHR  "); // carry=LSB

        // ---- ZERO FLAG check ------------------------------------
        a = 8'h00; b = 8'h00; opcode = 3'b000; #10; show("ADD0 "); // zero flag

        $display("============================================================");
        $finish;
    end

endmodule
