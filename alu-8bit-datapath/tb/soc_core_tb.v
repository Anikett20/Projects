// ============================================================
//  Integration Testbench — SoC Core (ALU + Register File)
//  File    : soc_core_tb.v
//  Sim     : iverilog soc_core_tb.v soc_core.v alu.v reg_file.v -o soc_sim && vvp soc_sim
// ============================================================

`timescale 1ns/1ps

module soc_core_tb;

    // ── DUT Signals ──────────────────────────────────────────
    reg        clk, reset, write_en;
    reg  [2:0] opcode, reg_src_a, reg_src_b, reg_dst;
    wire       zero_flag, carry_flag;

    // ── Instantiate SoC Core ─────────────────────────────────
    soc_core dut (
        .clk        (clk),
        .reset      (reset),
        .opcode     (opcode),
        .reg_src_a  (reg_src_a),
        .reg_src_b  (reg_src_b),
        .reg_dst    (reg_dst),
        .write_en   (write_en),
        .zero_flag  (zero_flag),
        .carry_flag (carry_flag)
    );

    // ── Clock ─────────────────────────────────────────────────
    initial clk = 0;
    always #5 clk = ~clk;

    // ── Helper task ───────────────────────────────────────────
    task run_op;
        input [55:0] label;      // 7-char description
        input [2:0]  op, ra, rb, rd;
        input        wen;
        begin
            opcode    = op;
            reg_src_a = ra;
            reg_src_b = rb;
            reg_dst   = rd;
            write_en  = wen;
            @(posedge clk); #1;
            $display("| %-8s | srcA=R%0d srcB=R%0d dst=R%0d | Zero=%b Carry=%b |",
                     label, ra, rb, rd, zero_flag, carry_flag);
        end
    endtask

    // ── Stimulus: simulates a mini "program" ─────────────────
    //
    //   Pseudo-program:
    //     1. Load 0x0F into R1  (via ADD R0+imm trick: store first via tb)
    //     2. Load 0x01 into R2
    //     3. R3 = R1 + R2      (ADD)
    //     4. R4 = R3 - R2      (SUB)
    //     5. R5 = R1 AND R2    (AND)
    //     6. R6 = R1 OR  R2    (OR)
    //     7. R3 = R3 XOR R3   (XOR same → zero flag should fire)
    //     8. SHL R1 → R1
    //
    //   Since we have no immediate-load instruction yet, we directly
    //   pre-load registers via the write port (simulating a future
    //   LOAD instruction from the Control Unit).
    // ─────────────────────────────────────────────────────────

    initial begin
        $display("=================================================================");
        $display("      SoC Core Integration Test — ALU + Register File           ");
        $display("=================================================================");

        // ---- Reset -----------------------------------------------
        reset = 1; write_en = 0;
        opcode = 0; reg_src_a = 0; reg_src_b = 0; reg_dst = 0;
        @(posedge clk); #1;
        reset = 0;
        $display("[RESET] System reset complete.");
        $display("-----------------------------------------------------------------");

        // ---- Pre-load R1 = 0x0F via write port -------------------
        // (Simulates a LOAD / MOV instruction)
        force dut.u_reg_file.registers[1] = 8'h0F;
        force dut.u_reg_file.registers[2] = 8'h01;
        #1;
        release dut.u_reg_file.registers[1];
        release dut.u_reg_file.registers[2];
        $display("[LOAD ] R1=0x0F, R2=0x01 pre-loaded (simulating LOAD instruction)");
        $display("-----------------------------------------------------------------");

        // ---- Operations ─────────────────────────────────────────
        //             label     op       rA   rB   rD   wen
        run_op("ADD    ", 3'b000, 3'd1, 3'd2, 3'd3, 1);  // R3 = 0x0F+0x01 = 0x10
        run_op("SUB    ", 3'b001, 3'd3, 3'd2, 3'd4, 1);  // R4 = 0x10-0x01 = 0x0F
        run_op("AND    ", 3'b010, 3'd1, 3'd2, 3'd5, 1);  // R5 = 0x0F & 0x01 = 0x01
        run_op("OR     ", 3'b011, 3'd1, 3'd2, 3'd6, 1);  // R6 = 0x0F | 0x01 = 0x0F
        run_op("XOR=0  ", 3'b100, 3'd3, 3'd3, 3'd3, 1);  // R3 = R3^R3 = 0x00 → ZERO FLAG
        run_op("SHL R1 ", 3'b110, 3'd1, 3'd0, 3'd1, 1);  // R1 = 0x0F<<1 = 0x1E
        run_op("SHR R1 ", 3'b111, 3'd1, 3'd0, 3'd1, 1);  // R1 = 0x1E>>1 = 0x0F
        run_op("NOT R2 ", 3'b101, 3'd2, 3'd0, 3'd7, 1);  // R7 = ~0x01 = 0xFE

        // ---- Final reset check ----------------------------------
        reset = 1; write_en = 0;
        @(posedge clk); #1;
        reset = 0;
        $display("-----------------------------------------------------------------");
        $display("[RESET] Second reset — all registers cleared.");
        $display("=================================================================");
        $finish;
    end

endmodule
