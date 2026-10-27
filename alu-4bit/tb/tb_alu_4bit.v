`timescale 1ns / 1ps

module tb_alu_4bit;

    // Inputs
    reg clk;
    reg rst;
    reg [3:0] a;
    reg [3:0] b;
    reg [2:0] opcode;

    // Outputs
    wire [3:0] result;
    wire carry_out;
    wire zero;

    // Instantiate the Unit Under Test (UUT)
    alu_4bit uut (
        .clk(clk), 
        .rst(rst), 
        .a(a), 
        .b(b), 
        .opcode(opcode), 
        .result(result), 
        .carry_out(carry_out), 
        .zero(zero)
    );

    // Clock generation (10 ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Dump waveform for Verdi
    initial begin
    //   $fsdbDumpfile("alu_4bit.fsdb");
    //   $fsdbDumpvars(0, tb_alu_4bit);
        $dumpfile("alu_4bit.vcd"); // Backup VCD just in case
        $dumpvars(0, tb_alu_4bit);
    end

    // Test sequence
    initial begin
        // Initialize Inputs
        rst = 1;
        a = 4'b0000;
        b = 4'b0000;
        opcode = 3'b000;

        // Wait for global reset
        #12; // Deassert reset away from the rising clock edge.
        rst = 0;

        // Test Case 1: ADD (5 + 3 = 8)
        a = 4'b0101; b = 4'b0011; opcode = 3'b000;
        #10;
        
        // Test Case 2: ADD with Carry (10 + 7 = 17 -> Result 1, Carry 1)
        a = 4'b1010; b = 4'b0111; opcode = 3'b000;
        #10;

        // Test Case 3: SUB (9 - 4 = 5)
        a = 4'b1001; b = 4'b0100; opcode = 3'b001;
        #10;

        // Test Case 4: AND (1100 & 1010 = 1000)
        a = 4'b1100; b = 4'b1010; opcode = 3'b010;
        #10;

        // Test Case 5: OR (1100 | 1010 = 1110)
        a = 4'b1100; b = 4'b1010; opcode = 3'b011;
        #10;

        // Test Case 6: XOR (1100 ^ 1010 = 0110)
        a = 4'b1100; b = 4'b1010; opcode = 3'b100;
        #10;

        // Test Case 7: NOT A (~0011 = 1100)
        a = 4'b0011; b = 4'b0000; opcode = 3'b101;
        #10;

        // Test Case 8: Logical Shift Left (0011 << 1 = 0110)
        a = 4'b0011; opcode = 3'b110;
        #10;

        // Test Case 9: Zero Flag trigger (4 - 4 = 0)
        a = 4'b0100; b = 4'b0100; opcode = 3'b001;
        #10;

        $display("Simulation Complete.");
        $finish;
    end
      
endmodule