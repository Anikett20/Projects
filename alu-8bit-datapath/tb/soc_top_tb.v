// ============================================================
//  Full SoC Integration Testbench
//  File    : soc_top_tb.v
//  Sim     : iverilog soc_top_tb.v soc_top.v control_unit.v reg_file.v alu.v -o soc_top_sim && vvp soc_top_sim
//
//  Runs a real 8-instruction "program":
//    1. LOAD R1, 0x0F        R1 = 15
//    2. LOAD R2, 0x05        R2 = 5
//    3. ADD  R3, R1, R2      R3 = 20  (0x14)
//    4. SUB  R4, R3, R2      R4 = 15  (0x0F)
//    5. AND  R5, R1, R2      R5 = 0x05
//    6. SHL  R6, R1          R6 = 0x1E
//    7. XOR  R3, R3, R3      R3 = 0x00 → ZERO FLAG
//    8. HLT
// ============================================================

`timescale 1ns/1ps

module soc_top_tb;

    reg         clk, reset;
    reg  [15:0] instruction;
    wire [7:0]  result;
    wire        zero_flag, carry_flag, halt;

    // ── Instantiate full SoC ─────────────────────────────
    soc_top dut (
        .clk         (clk),
        .reset       (reset),
        .instruction (instruction),
        .result      (result),
        .zero_flag   (zero_flag),
        .carry_flag  (carry_flag),
        .halt        (halt)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // ── Program Memory (ROM) — 8 instructions ────────────
    reg [15:0] prog_mem [0:7];
    integer    pc;         // Program Counter

    initial begin
        // LOAD R1 = 0x0F  → opcode=1000, rd=001, imm=0x0F
        prog_mem[0] = {4'b1000, 3'd1, 1'b0, 8'h0F};

        // LOAD R2 = 0x05
        prog_mem[1] = {4'b1000, 3'd2, 1'b0, 8'h05};

        // ADD  R3 = R1 + R2
        prog_mem[2] = {4'b0000, 3'd3, 3'd1, 3'd2, 3'b000};

        // SUB  R4 = R3 - R2
        prog_mem[3] = {4'b0001, 3'd4, 3'd3, 3'd2, 3'b000};

        // AND  R5 = R1 & R2
        prog_mem[4] = {4'b0010, 3'd5, 3'd1, 3'd2, 3'b000};

        // SHL  R6 = R1 << 1
        prog_mem[5] = {4'b0110, 3'd6, 3'd1, 3'd0, 3'b000};

        // XOR  R3 = R3 ^ R3  (zero flag)
        prog_mem[6] = {4'b0100, 3'd3, 3'd3, 3'd3, 3'b000};

        // HLT
        prog_mem[7] = {4'b1011, 3'd0, 3'd0, 3'd0, 3'b000};
    end

    // ── Display helper ────────────────────────────────────
    task show;
        input [7:0] pc_val;
        begin
            @(posedge clk); #2;
            $display("| PC=%0d | instr=0x%04h | result=0x%02h | zero=%b carry=%b halt=%b |",
                pc_val, instruction, result, zero_flag, carry_flag, halt);
        end
    endtask

    // ── Run program ───────────────────────────────────────
    initial begin
        $display("=================================================================");
        $display("        Full SoC Integration Test — Running Program             ");
        $display("=================================================================");
        $display("  Program: LOAD×2 → ADD → SUB → AND → SHL → XOR(zero) → HLT   ");
        $display("-----------------------------------------------------------------");

        // Reset
        reset = 1; instruction = 16'b0; pc = 0;
        @(posedge clk); #1;
        reset = 0;

        // Execute each instruction
        begin : run_prog
            integer i;
            for (i = 0; i < 8; i = i + 1) begin
                instruction = prog_mem[i];
                show(i);
                if (halt) begin
                    $display("-----------------------------------------------------------------");
                    $display("[HLT] Processor halted at PC=%0d", i);
                    disable run_prog;
                end
            end
        end

        $display("=================================================================");
        $finish;
    end

endmodule
