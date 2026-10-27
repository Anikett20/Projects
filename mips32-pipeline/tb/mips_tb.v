`timescale 1ns / 1ps
// =============================================================================
// File        : mips_tb.v
// Project     : 32-bit 5-Stage Pipelined MIPS Processor (OpenLane SKY130)
// Description : Self-Checking Testbench for 32-bit 5-Stage Pipelined MIPS
//               Verifies Jump (J) + flush, Taken/Not-Taken BNE + flush,
//               EX/MEM & MEM/WB forwarding, SW/LW memory access,
//               Load-Use Hazard Stall (LW -> SLT), and Jump Register (JR).
// =============================================================================

module MIPSStimulus();

    reg         clk;
    reg         reset;
    integer     cyc;
    integer     errors;

    wire [31:0] pc_out;
    wire [31:0] alu_result_out;
    wire [31:0] mem_data_out;
    wire [31:0] wb_data_out;
    wire [4:0]  wb_reg_out;
    wire        wb_regwrite_out;

    MIPSpipeline myMIPS (
        .clk             (clk),
        .reset           (reset),
        .pc_out          (pc_out),
        .alu_result_out  (alu_result_out),
        .mem_data_out    (mem_data_out),
        .wb_data_out     (wb_data_out),
        .wb_reg_out      (wb_reg_out),
        .wb_regwrite_out (wb_regwrite_out)
    );

    initial begin
        clk = 0;
        forever #10 clk = ~clk; // 50 MHz (20 ns period)
    end

    initial begin
        $dumpfile("mips32_waveform.vcd");
        $dumpvars(0, MIPSStimulus);
    end

    initial begin
        errors = 0;
        reset  = 1;
        #25;
        reset  = 0;

        $display("==========================================================================================");
        $display(" 32-Bit 5-Stage Pipelined MIPS Processor Self-Checking Simulation (50 MHz)");
        $display("==========================================================================================");

        for (cyc = 0; cyc < 24; cyc = cyc + 1) begin
            @(posedge clk);
            #1;
            $display("Cycle %2d | PC=0x%08h | EX_ALU=0x%08h | MEM_RD=0x%08h | WB_Reg=$%02d | WB_Data=0x%08h | WB_WE=%b",
                     cyc, pc_out, alu_result_out, mem_data_out, wb_reg_out, wb_data_out, wb_regwrite_out);
        end

        // Verify architectural register values and Data Memory after full loop completion (Cycle 23)
        if (myMIPS.Register_File.RegArray[16] !== 32'h00000001) begin
            $display("[FAIL] $16 = 0x%08h (Expected 0x00000001)", myMIPS.Register_File.RegArray[16]); errors = errors + 1;
        end else $display("[PASS] $16 = 0x%08h (XORI $16, $0, 1 after BNE loop)", myMIPS.Register_File.RegArray[16]);

        if (myMIPS.Register_File.RegArray[17] !== 32'h00000001) begin
            $display("[FAIL] $17 = 0x%08h (Expected 0x00000001)", myMIPS.Register_File.RegArray[17]); errors = errors + 1;
        end else $display("[PASS] $17 = 0x%08h (XORI $17, $0, 1 after BNE loop)", myMIPS.Register_File.RegArray[17]);

        if (myMIPS.Register_File.RegArray[18] !== 32'h00000000) begin
            $display("[FAIL] $18 = 0x%08h (Expected 0x00000000)", myMIPS.Register_File.RegArray[18]); errors = errors + 1;
        end else $display("[PASS] $18 = 0x%08h (SUB $18, $17, $16 = 0 with EX/MEM & MEM/WB forwarding)", myMIPS.Register_File.RegArray[18]);

        if (myMIPS.Register_File.RegArray[19] !== 32'h00000001) begin
            $display("[FAIL] $19 = 0x%08h (Expected 0x00000001)", myMIPS.Register_File.RegArray[19]); errors = errors + 1;
        end else $display("[PASS] $19 = 0x%08h (XORI $19, $18, 1 = 1)", myMIPS.Register_File.RegArray[19]);

        if (myMIPS.Register_File.RegArray[20] !== 32'h00000002) begin
            $display("[FAIL] $20 = 0x%08h (Expected 0x00000002)", myMIPS.Register_File.RegArray[20]); errors = errors + 1;
        end else $display("[PASS] $20 = 0x%08h (LW $20, 16($18) = 2)", myMIPS.Register_File.RegArray[20]);

        if (myMIPS.Register_File.RegArray[21] !== 32'h00000000) begin
            $display("[FAIL] $21 = 0x%08h (Expected 0x00000000)", myMIPS.Register_File.RegArray[21]); errors = errors + 1;
        end else $display("[PASS] $21 = 0x%08h (SLT Load-Use stall -> XORI $21, $21, 1 -> JR $21 = 0)", myMIPS.Register_File.RegArray[21]);

        if (myMIPS.dataMem1.datamem[4] !== 32'h00000002) begin
            $display("[FAIL] DMEM[4] (addr 16) = 0x%08h (Expected 0x00000002)", myMIPS.dataMem1.datamem[4]); errors = errors + 1;
        end else $display("[PASS] DMEM[4] (addr 16) = 0x%08h (SW $19, 16($18) store forwarding verified)", myMIPS.dataMem1.datamem[4]);

        $display("==========================================================================================");
        if (errors == 0) begin
            $display(" [SELF-CHECK PASS] 32-Bit 5-Stage Pipelined MIPS Verification Complete (0 Errors)!");
        end else begin
            $display(" [SELF-CHECK FAIL] %0d errors detected!", errors);
        end
        $display("==========================================================================================");
        $finish;
    end

endmodule
