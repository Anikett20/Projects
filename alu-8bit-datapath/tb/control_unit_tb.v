// ============================================================
//  Testbench — Control Unit
//  File    : control_unit_tb.v
//  Sim     : iverilog control_unit_tb.v control_unit.v -o cu_sim && vvp cu_sim
// ============================================================

`timescale 1ns/1ps

module control_unit_tb;

    reg  [15:0] instruction;
    reg         clk, reset, zero_flag, carry_flag;

    wire [2:0]  opcode, reg_src_a, reg_src_b, reg_dst;
    wire        write_en, imm_sel, halt;
    wire [7:0]  imm_data;

    control_unit dut (
        .clk         (clk),
        .reset       (reset),
        .instruction (instruction),
        .zero_flag   (zero_flag),
        .carry_flag  (carry_flag),
        .opcode      (opcode),
        .reg_src_a   (reg_src_a),
        .reg_src_b   (reg_src_b),
        .reg_dst     (reg_dst),
        .write_en    (write_en),
        .imm_data    (imm_data),
        .imm_sel     (imm_sel),
        .halt        (halt)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task decode;
        input [87:0] label;
        begin
            #2;
            $display("| %-10s | op=%03b rD=R%0d rA=R%0d rB=R%0d | wen=%b imm_sel=%b imm=0x%02h halt=%b |",
                label, opcode, reg_dst, reg_src_a, reg_src_b,
                write_en, imm_sel, imm_data, halt);
        end
    endtask

    initial begin
        $display("================================================================");
        $display("          Control Unit Decode — Test Results                   ");
        $display("================================================================");

        reset = 1; zero_flag = 0; carry_flag = 0;
        instruction = 16'b0;
        @(posedge clk); #1; reset = 0;

        // ── Format: [15:12]=OPCODE [11:9]=RD [8:6]=RA [5:3]=RB ──

        // ADD R3 = R1 + R2  → 0000_011_001_010_000
        instruction = {4'b0000, 3'd3, 3'd1, 3'd2, 3'b000};
        decode("ADD      ");

        // SUB R4 = R3 - R1  → 0001_100_011_001_000
        instruction = {4'b0001, 3'd4, 3'd3, 3'd1, 3'b000};
        decode("SUB      ");

        // AND R5 = R1 & R2
        instruction = {4'b0010, 3'd5, 3'd1, 3'd2, 3'b000};
        decode("AND      ");

        // OR  R6 = R1 | R2
        instruction = {4'b0011, 3'd6, 3'd1, 3'd2, 3'b000};
        decode("OR       ");

        // XOR R3 = R3 ^ R3  (should produce zero)
        instruction = {4'b0100, 3'd3, 3'd3, 3'd3, 3'b000};
        decode("XOR      ");

        // NOT R7 = ~R2
        instruction = {4'b0101, 3'd7, 3'd2, 3'd0, 3'b000};
        decode("NOT      ");

        // SHL R1 = R1 << 1
        instruction = {4'b0110, 3'd1, 3'd1, 3'd0, 3'b000};
        decode("SHL      ");

        // SHR R1 = R1 >> 1
        instruction = {4'b0111, 3'd1, 3'd1, 3'd0, 3'b000};
        decode("SHR      ");

        // LOAD R2 = 0xAB  → opcode=1000, rd=R2, imm=0xAB
        instruction = {4'b1000, 3'd2, 3'd0, 8'hAB};
        decode("LOAD     ");

        // MOV R4 = R1
        instruction = {4'b1001, 3'd4, 3'd1, 3'd0, 3'b000};
        decode("MOV      ");

        // NOP
        instruction = {4'b1010, 3'd0, 3'd0, 3'd0, 3'b000};
        decode("NOP      ");

        // HLT
        instruction = {4'b1011, 3'd0, 3'd0, 3'd0, 3'b000};
        decode("HLT      ");

        $display("================================================================");
        $finish;
    end

endmodule
