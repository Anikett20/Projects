// ============================================================
//  Testbench for 8-Bit SoC Register File
//  File    : reg_file_tb.v
//  Sim     : iverilog reg_file_tb.v reg_file.v -o rf_sim && vvp rf_sim
// ============================================================

`timescale 1ns/1ps

module reg_file_tb;

    // ── DUT Signals ──────────────────────────────────────────
    reg        clk, reset, write_en;
    reg  [2:0] write_addr, read_addr_a, read_addr_b;
    reg  [7:0] write_data;
    wire [7:0] read_data_a, read_data_b;

    // ── Instantiate DUT ──────────────────────────────────────
    reg_file dut (
        .clk         (clk),
        .reset       (reset),
        .write_en    (write_en),
        .write_addr  (write_addr),
        .write_data  (write_data),
        .read_addr_a (read_addr_a),
        .read_addr_b (read_addr_b),
        .read_data_a (read_data_a),
        .read_data_b (read_data_b)
    );

    // ── Clock: 10 ns period ───────────────────────────────────
    initial clk = 0;
    always #5 clk = ~clk;

    // ── Stimulus ─────────────────────────────────────────────
    initial begin
        $display("=======================================================");
        $display("        Register File – Test Results                   ");
        $display("=======================================================");

        // ---- Reset -----------------------------------------------
        reset = 1; write_en = 0;
        write_addr = 0; write_data = 0;
        read_addr_a = 0; read_addr_b = 0;
        @(posedge clk); #1;
        reset = 0;
        $display("[RESET] All registers cleared.");

        // ---- Write to R1 = 0xAA ---------------------------------
        write_en = 1; write_addr = 3'd1; write_data = 8'hAA;
        @(posedge clk); #1;
        read_addr_a = 3'd1;
        #1;
        $display("[WRITE] R1 = 0xAA  | Read R1 via port A = 0x%02h  (expect AA)", read_data_a);

        // ---- Write to R2 = 0x55 ---------------------------------
        write_addr = 3'd2; write_data = 8'h55;
        @(posedge clk); #1;
        read_addr_a = 3'd1; read_addr_b = 3'd2;
        #1;
        $display("[WRITE] R2 = 0x55  | Read R1=0x%02h, R2=0x%02h  (expect AA, 55)",
                 read_data_a, read_data_b);

        // ---- Dual read (two ports simultaneously) ---------------
        read_addr_a = 3'd2; read_addr_b = 3'd1;
        #1;
        $display("[READ ] Swap ports | A=0x%02h (R2), B=0x%02h (R1)  (expect 55, AA)",
                 read_data_a, read_data_b);

        // ---- Try writing R0 (should be ignored) -----------------
        write_addr = 3'd0; write_data = 8'hFF;
        @(posedge clk); #1;
        read_addr_a = 3'd0;
        #1;
        $display("[GUARD] Write 0xFF→R0 | Read R0 = 0x%02h  (expect 00, R0 is zero reg)",
                 read_data_a);

        // ---- Write to R7 = 0x3C ---------------------------------
        write_en = 1; write_addr = 3'd7; write_data = 8'h3C;
        @(posedge clk); #1;
        read_addr_b = 3'd7;
        #1;
        $display("[WRITE] R7 = 0x3C  | Read R7 via port B = 0x%02h  (expect 3C)", read_data_b);

        // ---- Reset clears everything ----------------------------
        write_en = 0; reset = 1;
        @(posedge clk); #1;
        reset = 0;
        read_addr_a = 3'd1; read_addr_b = 3'd2;
        #1;
        $display("[RESET] After reset | R1=0x%02h, R2=0x%02h  (expect 00, 00)",
                 read_data_a, read_data_b);

        $display("=======================================================");
        $finish;
    end

endmodule
