`timescale 10ns / 1ps
// =============================================================================
// File        : FPMM_tb.v
// Project     : 4x4 Fixed-Point Matrix Multiplication (OpenLane SKY130 Target)
// Description : Self-Checking Testbench for 4x4 Q7.8 Matrix Multiplier
//               - Executes original stimulus sequence + VCD waveform dump
//               - Verifies all 16 Q7.8 output elements against golden reference
//               - Writes result.dat and prints formatted 4x4 matrix summary
// =============================================================================

module tb_top;

    reg         clk;
    reg         reset;
    integer     i;
    wire [15:0] data_out;
    reg  [15:0] matrix_out [0:15];
    reg  [15:0] expected_out [0:15];
    integer     fd;
    integer     errors;

    parameter INFILE = "result.dat";

    // Instantiate Unit Under Test (UUT)
    matrix_multiplication uut (
        .clk      (clk),
        .reset    (reset),
        .data_out (data_out)
    );

    // Golden Q7.8 Fixed-Point Reference Matrix C = A * B
    initial begin
        expected_out[0]  = 16'h06C0; // C[0][0] = +6.7500
        expected_out[1]  = 16'h02C0; // C[0][1] = +2.7500
        expected_out[2]  = 16'h82C0; // C[0][2] = -2.7500
        expected_out[3]  = 16'h0500; // C[0][3] = +5.0000
        expected_out[4]  = 16'h8440; // C[1][0] = -4.2500
        expected_out[5]  = 16'h8260; // C[1][1] = -2.3750
        expected_out[6]  = 16'h07A0; // C[1][2] = +7.6250
        expected_out[7]  = 16'h8040; // C[1][3] = -0.2500
        expected_out[8]  = 16'h03E0; // C[2][0] = +3.8750
        expected_out[9]  = 16'h03A0; // C[2][1] = +3.6250
        expected_out[10] = 16'h0390; // C[2][2] = +3.5625
        expected_out[11] = 16'h8010; // C[2][3] = -0.0625
        expected_out[12] = 16'h0360; // C[3][0] = +3.3750
        expected_out[13] = 16'h8100; // C[3][1] = -1.0000
        expected_out[14] = 16'h83A0; // C[3][2] = -3.6250
        expected_out[15] = 16'h0560; // C[3][3] = +5.3750
    end

    initial begin
        $dumpfile("fpmm_waveform.vcd");
        $dumpvars(0, tb_top);
    end

    initial begin
        fd = $fopen(INFILE, "wb+");
    end

    initial begin
        errors = 0;
        reset  = 1;
        clk    = 0;

        // Wait 100 time units for global reset
        #100;
        reset = 0;
        for (i = 0; i < 32; i = i + 1) begin
            #100 clk = ~clk;
        end

        #10000;
        reset = 1;
        #1000;
        reset = 0;

        // Phase 1: 16 clock cycles to load Matrix A & Matrix B from ROMs
        for (i = 0; i < 32; i = i + 1) begin
            #100 clk = ~clk;
        end

        // Phase 2: 32 clock cycles (16 write cycles to matrix_out + 16 wrap cycles)
        for (i = 0; i < 64; i = i + 1) begin
            #100 clk = ~clk;
        end

        // Phase 3: 16 clock cycles to stream out all 16 Q7.8 elements of C = A * B
        clk = 0;
        for (i = 0; i < 32; i = i + 1) begin
            #100 clk = ~clk;
            matrix_out[i/2] = data_out;
        end

        #100;
        $display("=====================================================================");
        $display(" 4x4 Q7.8 Fixed-Point Matrix Multiplication Self-Check Verification");
        $display("=====================================================================");
        for (i = 0; i < 16; i = i + 1) begin
            $fwrite(fd, "%d", matrix_out[i][15:8]);
            $fwrite(fd, "%d", matrix_out[i][7:0]);
            if (matrix_out[i] !== expected_out[i]) begin
                $display("[FAIL] C[%0d][%0d] (idx %2d): Got 0x%04h | Expected 0x%04h",
                         i/4, i%4, i, matrix_out[i], expected_out[i]);
                errors = errors + 1;
            end else begin
                $display("[PASS] C[%0d][%0d] (idx %2d): Got 0x%04h == Expected 0x%04h (Sign=%0d, Int=%2d, Frac=%3d/256)",
                         i/4, i%4, i, matrix_out[i], expected_out[i],
                         matrix_out[i][15], matrix_out[i][14:8], matrix_out[i][7:0]);
            end
            #200;
        end
        $fclose(fd);

        $display("=====================================================================");
        if (errors == 0) begin
            $display(" [SELF-CHECK PASS] All 16 Q7.8 Fixed-Point Matrix Products Verified!");
        end else begin
            $display(" [SELF-CHECK FAIL] %0d mismatches detected!", errors);
        end
        $display("=====================================================================");
        $finish;
    end

endmodule
