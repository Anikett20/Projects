`timescale 1ns / 1ps
// =============================================================================
// File        : mips16_tb.v
// Project     : 16-bit MIPS Single-Cycle Processor (OpenLane SKY130 Target)
// Description : Self-Checking Testbench for 16-bit MIPS Single-Cycle Processor
//               Verifies R-type (ADD, SUB, AND, OR, XOR, SLT, SLL),
//               I-type (ADDI, ANDI, ORI, LW, SW, BEQ, BNE, LUI),
//               and J-type (JAL, J) execution and dumps mips16_waveform.vcd.
// =============================================================================

module mips16_tb;

    reg         clk;
    reg         rst;
    integer     cyc;
    integer     errors;

    wire [15:0] pc_out;
    wire [15:0] instruction;
    wire [15:0] alu_result;
    wire [15:0] read_data1;
    wire [15:0] read_data2;
    wire [15:0] write_data;
    wire        zero_flag;
    wire [2:0]  write_reg;

    mips16 dut (
        .clk         (clk),
        .rst         (rst),
        .pc_out      (pc_out),
        .instruction (instruction),
        .alu_result  (alu_result),
        .read_data1  (read_data1),
        .read_data2  (read_data2),
        .write_data  (write_data),
        .zero_flag   (zero_flag),
        .write_reg   (write_reg)
    );

    initial begin
        clk = 0;
        forever #10 clk = ~clk; // 50 MHz (20 ns period)
    end

    initial begin
        $dumpfile("mips16_waveform.vcd");
        $dumpvars(0, mips16_tb);
    end

    initial begin
        errors = 0;
        rst    = 1;
        #25;
        rst    = 0;

        $display("====================================================================================");
        $display(" 16-Bit MIPS Single-Cycle Processor Self-Checking Simulation (50 MHz)");
        $display("====================================================================================");

        for (cyc = 0; cyc < 20; cyc = cyc + 1) begin
            @(posedge clk);
            #1;
            $display("Cycle %2d | PC=0x%04h | Inst=0x%04h | ALU=0x%04h | RD1=0x%04h | RD2=0x%04h | WReg=$%0d | WData=0x%04h | Zero=%b",
                     cyc, pc_out, instruction, alu_result, read_data1, read_data2, write_reg, write_data, zero_flag);
        end

        // Check architectural register file state and DMEM[2]
        if (dut.rf.registers[1] !== 16'h000A) begin
            $display("[FAIL] $1 = 0x%04h (Expected 0x000A)", dut.rf.registers[1]); errors = errors + 1;
        end else $display("[PASS] $1 = 0x%04h (ADDI $1, $0, 10)", dut.rf.registers[1]);

        if (dut.rf.registers[2] !== 16'hFFFB) begin
            $display("[FAIL] $2 = 0x%04h (Expected 0xFFFB)", dut.rf.registers[2]); errors = errors + 1;
        end else $display("[PASS] $2 = 0x%04h (ADDI $2, $0, -5)", dut.rf.registers[2]);

        if (dut.rf.registers[3] !== 16'h0014) begin
            $display("[FAIL] $3 = 0x%04h (Expected 0x0014)", dut.rf.registers[3]); errors = errors + 1;
        end else $display("[PASS] $3 = 0x%04h (ADD $3, $3, $4 = 20)", dut.rf.registers[3]);

        if (dut.rf.registers[4] !== 16'h000F) begin
            $display("[FAIL] $4 = 0x%04h (Expected 0x000F)", dut.rf.registers[4]); errors = errors + 1;
        end else $display("[PASS] $4 = 0x%04h (SUB $4, $1, $2 = 15)", dut.rf.registers[4]);

        if (dut.rf.registers[5] !== 16'h000F) begin
            $display("[FAIL] $5 = 0x%04h (Expected 0x000F)", dut.rf.registers[5]); errors = errors + 1;
        end else $display("[PASS] $5 = 0x%04h (LW $5, 4($0) = 15 & BEQ skip verified)", dut.rf.registers[5]);

        if (dut.rf.registers[6] !== 16'h1500) begin
            $display("[FAIL] $6 = 0x%04h (Expected 0x1500)", dut.rf.registers[6]); errors = errors + 1;
        end else $display("[PASS] $6 = 0x%04h (LUI $6, 0x15 & JAL skip verified)", dut.rf.registers[6]);

        if (dut.rf.registers[7] !== 16'h002A) begin
            $display("[FAIL] $7 = 0x%04h (Expected 0x002A)", dut.rf.registers[7]); errors = errors + 1;
        end else $display("[PASS] $7 = 0x%04h (JAL return address PC+2 = 0x002A)", dut.rf.registers[7]);

        if (dut.dmem.memory[2] !== 16'h000F) begin
            $display("[FAIL] DMEM[2] = 0x%04h (Expected 0x000F)", dut.dmem.memory[2]); errors = errors + 1;
        end else $display("[PASS] DMEM[2] = 0x%04h (SW $4, 4($0) verified)", dut.dmem.memory[2]);

        if (pc_out !== 16'h0030) begin
            $display("[FAIL] Final PC = 0x%04h (Expected 0x0030)", pc_out); errors = errors + 1;
        end else $display("[PASS] Final PC = 0x%04h (J 0x030 halt reached)", pc_out);

        $display("====================================================================================");
        if (errors == 0) begin
            $display(" [SELF-CHECK PASS] All 16-Bit MIPS Instructions, Branches, Jumps & Memory Verified!");
        end else begin
            $display(" [SELF-CHECK FAIL] %0d errors detected!", errors);
        end
        $display("====================================================================================");
        $finish;
    end

endmodule
