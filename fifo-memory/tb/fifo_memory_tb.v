`timescale 1ns / 1ps
// ============================================================================
// File        : fifo_memory_tb.v
// Project     : 32-Bit Synchronous FIFO Memory (OpenLane SKY130 Target)
// Description : Comprehensive 8-Suite Self-Checking Testbench for 32-Bit
//               Synchronous FIFO (DATA_WIDTH = 32, DEPTH = 16, THRESHOLD = 8)
// ============================================================================

module tb_fifo_memory;

    parameter DEPTH      = 16;
    parameter DATA_WIDTH = 32;
    parameter CLK_PERIOD = 20; // 50 MHz

    reg                   clk;
    reg                   rst_n;

    // Simple 32-bit FIFO signals (fifo_memo)
    reg                   wr;
    reg                   rd;
    reg  [DATA_WIDTH-1:0] data_in;
    wire [DATA_WIDTH-1:0] data_out;
    wire                  fifo_full;
    wire                  fifo_empty;
    wire                  fifo_th;
    wire                  fifo_ovf;
    wire                  fifo_ufl;

    // Parameterized 32-bit FIFO signals (fifo_memory)
    reg                   wr_en;
    reg                   rd_en;
    reg  [DATA_WIDTH-1:0] data_in_p;
    wire [DATA_WIDTH-1:0] data_out_p;
    wire                  fifo_full_p;
    wire                  fifo_empty_p;
    wire                  fifo_th_p;
    wire                  fifo_ovf_p;
    wire                  fifo_ufl_p;

    integer i;
    integer errors;
    reg [DATA_WIDTH-1:0] expected_data [0:DEPTH-1];
    integer wr_idx, rd_idx;

    integer param_wr_idx, param_rd_idx;
    reg [DATA_WIDTH-1:0] param_expected [0:DEPTH-1];

    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Instantiate 32-bit simple structural FIFO
    fifo_memo u_fifo_simple (
        .wr         (wr),
        .rd         (rd),
        .clk        (clk),
        .rst_n      (rst_n),
        .data_in    (data_in),
        .data_out   (data_out),
        .fifo_full  (fifo_full),
        .fifo_empty (fifo_empty),
        .fifo_th    (fifo_th),
        .fifo_ovf   (fifo_ovf),
        .fifo_ufl   (fifo_ufl)
    );

    // Instantiate 32-bit parameterized Gray-pointer FIFO (Top Module for OpenLane)
    fifo_memory #(
        .DEPTH      (DEPTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (4),
        .THRESHOLD  (8)
    ) u_fifo_param (
        .clk        (clk),
        .rst_n      (rst_n),
        .wr_en      (wr_en),
        .rd_en      (rd_en),
        .data_in    (data_in_p),
        .data_out   (data_out_p),
        .fifo_full  (fifo_full_p),
        .fifo_empty (fifo_empty_p),
        .fifo_th    (fifo_th_p),
        .fifo_ovf   (fifo_ovf_p),
        .fifo_ufl   (fifo_ufl_p)
    );

    initial begin
        $dumpfile("fifo_waveform.vcd");
        $dumpvars(0, tb_fifo_memory);

        errors    = 0;
        rst_n     = 1'b0;
        wr        = 1'b0;
        rd        = 1'b0;
        data_in   = 32'h0000_0000;
        wr_en     = 1'b0;
        rd_en     = 1'b0;
        data_in_p = 32'h0000_0000;

        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        repeat (1) @(posedge clk);

        $display("================================================================");
        $display(" Starting 32-Bit Synchronous FIFO Memory Verification (16x32)");
        $display("================================================================");

        $display("\n--- Test 1: Basic 32-Bit Write/Read ---");
        wr_idx = 0; rd_idx = 0;
        test_basic_write_read();

        $display("\n--- Test 2: Fill 16x32 FIFO to Full ---");
        wr_idx = 0; rd_idx = 0;
        test_fill_to_full();

        $display("\n--- Test 3: Empty FIFO & Underflow Detection ---");
        test_empty_fifo();

        $display("\n--- Test 4: Sticky Overflow/Underflow Flag Set & Clear ---");
        test_overflow_underflow();

        $display("\n--- Test 5: Simultaneous 32-Bit Write & Read ---");
        test_simultaneous_wr_rd();

        $display("\n--- Test 6: Threshold Flag (8 x 32-Bit Words) ---");
        test_threshold();

        $display("\n--- Test 7: Reset Recovery During Operation ---");
        test_reset_during_op();

        $display("\n--- Test 8: Parameterized 32-Bit Gray-Pointer FIFO (Top) ---");
        test_param_fifo();

        $display("\n================================================================");
        if (errors == 0) begin
            $display(" [SELF-CHECK PASS] ALL 32-BIT SYNCHRONOUS FIFO TESTS PASSED!");
        end else begin
            $display(" [SELF-CHECK FAIL] %0d errors detected!", errors);
        end
        $display("================================================================");
        $finish;
    end

    task test_basic_write_read;
        begin
            for (i = 0; i < 5; i = i + 1) begin
                @(posedge clk);
                wr = 1'b1;
                data_in = 32'hA5A5_1000 + i;
                expected_data[wr_idx] = data_in;
                wr_idx = wr_idx + 1;
                @(posedge clk);
                wr = 1'b0;
            end
            for (i = 0; i < 5; i = i + 1) begin
                @(posedge clk);
                rd = 1'b1;
                @(posedge clk);
                rd = 1'b0;
                if (data_out !== expected_data[rd_idx]) begin
                    $display("ERROR: Read mismatch at idx %0d: got 0x%08h, expected 0x%08h",
                             rd_idx, data_out, expected_data[rd_idx]);
                    errors = errors + 1;
                end else begin
                    $display("PASS: Read 32-bit data[%0d] = 0x%08h", rd_idx, data_out);
                end
                rd_idx = rd_idx + 1;
            end
            @(posedge clk);
            if (!fifo_empty) begin
                $display("ERROR: FIFO should be empty");
                errors = errors + 1;
            end
        end
    endtask

    task test_fill_to_full;
        begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                @(posedge clk);
                wr = 1'b1;
                data_in = 32'hDEAD_2000 + i;
                expected_data[wr_idx] = data_in;
                wr_idx = wr_idx + 1;
                @(posedge clk);
                wr = 1'b0;
            end
            @(posedge clk);
            if (!fifo_full) begin
                $display("ERROR: FIFO should be full");
                errors = errors + 1;
            end else begin
                $display("PASS: FIFO full flag asserted at 16 x 32-bit words");
            end
            @(posedge clk);
            wr = 1'b1;
            data_in = 32'hFFFF_FFFF;
            @(posedge clk);
            wr = 1'b0;
            for (i = 0; i < DEPTH; i = i + 1) begin
                @(posedge clk);
                rd = 1'b1;
                @(posedge clk);
                rd = 1'b0;
                if (data_out !== expected_data[rd_idx]) begin
                    $display("ERROR: Read mismatch at idx %0d: got 0x%08h, expected 0x%08h",
                             rd_idx, data_out, expected_data[rd_idx]);
                    errors = errors + 1;
                end
                rd_idx = rd_idx + 1;
            end
        end
    endtask

    task test_empty_fifo;
        begin
            @(posedge clk);
            if (!fifo_empty) begin
                $display("ERROR: FIFO should be empty");
                errors = errors + 1;
            end else begin
                $display("PASS: FIFO empty flag asserted");
            end
            @(posedge clk);
            rd = 1'b1;
            @(posedge clk);
            rd = 1'b0;
            @(posedge clk);
            if (!fifo_ufl) begin
                $display("ERROR: Underflow flag should be set");
                errors = errors + 1;
            end else begin
                $display("PASS: Underflow flag asserted on empty read");
            end
        end
    endtask

    task test_overflow_underflow;
        begin
            @(posedge clk);
            wr = 1'b1;
            data_in = 32'hCAFE_BABE;
            @(posedge clk);
            wr = 1'b0;
            @(posedge clk);
            if (fifo_ufl) begin
                $display("ERROR: Underflow should clear on write");
                errors = errors + 1;
            end else begin
                $display("PASS: Underflow cleared on 32-bit write");
            end
            for (i = 1; i < DEPTH; i = i + 1) begin
                @(posedge clk);
                wr = 1'b1;
                data_in = 32'h3000_0000 + i;
                @(posedge clk);
                wr = 1'b0;
            end
            @(posedge clk);
            wr = 1'b1;
            data_in = 32'hEEEE_EEEE;
            @(posedge clk);
            wr = 1'b0;
            @(posedge clk);
            if (!fifo_ovf) begin
                $display("ERROR: Overflow flag should be set");
                errors = errors + 1;
            end else begin
                $display("PASS: Overflow flag asserted on full write");
            end
            @(posedge clk);
            rd = 1'b1;
            @(posedge clk);
            rd = 1'b0;
            @(posedge clk);
            if (fifo_ovf) begin
                $display("ERROR: Overflow should clear on read");
                errors = errors + 1;
            end else begin
                $display("PASS: Overflow cleared on 32-bit read");
            end
            for (i = 0; i < DEPTH-1; i = i + 1) begin
                @(posedge clk);
                rd = 1'b1;
                @(posedge clk);
                rd = 1'b0;
            end
        end
    endtask

    task test_simultaneous_wr_rd;
        begin
            for (i = 0; i < 3; i = i + 1) begin
                @(posedge clk);
                wr = 1'b1;
                data_in = 32'h4000_0000 + i;
                @(posedge clk);
                wr = 1'b0;
            end
            for (i = 0; i < 5; i = i + 1) begin
                @(posedge clk);
                wr = 1'b1;
                rd = 1'b1;
                data_in = 32'h5000_0000 + i;
                @(posedge clk);
                wr = 1'b0;
                rd = 1'b0;
            end
            while (!fifo_empty) begin
                @(posedge clk);
                rd = 1'b1;
                @(posedge clk);
                rd = 1'b0;
            end
            $display("PASS: Simultaneous 32-bit write/read test completed");
        end
    endtask

    task test_threshold;
        begin
            for (i = 0; i < 8; i = i + 1) begin
                @(posedge clk);
                wr = 1'b1;
                data_in = 32'h6000_0000 + i;
                @(posedge clk);
                wr = 1'b0;
            end
            @(posedge clk);
            if (!fifo_th) begin
                $display("ERROR: Threshold flag should be set at 8 items");
                errors = errors + 1;
            end else begin
                $display("PASS: Threshold flag asserted at 8 x 32-bit words");
            end
            @(posedge clk);
            rd = 1'b1;
            @(posedge clk);
            rd = 1'b0;
            @(posedge clk);
            if (fifo_th) begin
                $display("ERROR: Threshold flag should clear below 8 items");
                errors = errors + 1;
            end else begin
                $display("PASS: Threshold flag cleared at 7 x 32-bit words");
            end
            while (!fifo_empty) begin
                @(posedge clk);
                rd = 1'b1;
                @(posedge clk);
                rd = 1'b0;
            end
        end
    endtask

    task test_reset_during_op;
        begin
            for (i = 0; i < 5; i = i + 1) begin
                @(posedge clk);
                wr = 1'b1;
                data_in = 32'h7000_0000 + i;
                @(posedge clk);
                wr = 1'b0;
            end
            @(posedge clk);
            rst_n = 1'b0;
            @(posedge clk);
            @(posedge clk);
            rst_n = 1'b1;
            @(posedge clk);
            if (fifo_full || !fifo_empty || fifo_th || fifo_ovf || fifo_ufl) begin
                $display("ERROR: Flags not properly reset");
                errors = errors + 1;
            end else begin
                $display("PASS: All flags properly reset");
            end
        end
    endtask

    task test_param_fifo;
        begin
            param_wr_idx = 0;
            param_rd_idx = 0;
            for (i = 0; i < 5; i = i + 1) begin
                @(posedge clk);
                wr_en = 1'b1;
                data_in_p = 32'hCAFE_8000 + (i * 32'h0101_0101);
                param_expected[param_wr_idx] = data_in_p;
                param_wr_idx = param_wr_idx + 1;
                @(posedge clk);
                wr_en = 1'b0;
            end
            for (i = 0; i < 5; i = i + 1) begin
                @(posedge clk);
                rd_en = 1'b1;
                @(posedge clk);
                rd_en = 1'b0;
                if (data_out_p !== param_expected[param_rd_idx]) begin
                    $display("ERROR [Param 32-bit]: Read mismatch: got 0x%08h, expected 0x%08h",
                             data_out_p, param_expected[param_rd_idx]);
                    errors = errors + 1;
                end else begin
                    $display("PASS [Param 32-bit]: Read data[%0d] = 0x%08h", i, data_out_p);
                end
                param_rd_idx = param_rd_idx + 1;
            end
            for (i = 0; i < DEPTH; i = i + 1) begin
                @(posedge clk);
                wr_en = 1'b1;
                data_in_p = 32'h9000_0000 + i;
                @(posedge clk);
                wr_en = 1'b0;
            end
            @(posedge clk);
            if (!fifo_full_p) begin
                $display("ERROR [Param 32-bit]: FIFO should be full");
                errors = errors + 1;
            end else begin
                $display("PASS [Param 32-bit]: Full flag verified at 16 x 32-bit words");
            end
            for (i = 0; i < DEPTH; i = i + 1) begin
                @(posedge clk);
                rd_en = 1'b1;
                @(posedge clk);
                rd_en = 1'b0;
            end
            @(posedge clk);
            if (!fifo_empty_p) begin
                $display("ERROR [Param 32-bit]: FIFO should be empty");
                errors = errors + 1;
            end else begin
                $display("PASS [Param 32-bit]: Empty flag verified");
            end
        end
    endtask

endmodule
