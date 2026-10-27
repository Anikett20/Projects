`timescale 1ns / 1ps

module mips16_tb_detailed;

    reg clk;
    reg rst;

    wire [15:0] pc_out;
    wire [15:0] instruction;
    wire [15:0] alu_result;
    wire [15:0] read_data1;
    wire [15:0] read_data2;
    wire [15:0] write_data;
    wire        zero_flag;
    wire [2:0]  write_reg;
    wire [3:0]  opcode;
    wire [2:0]  rs, rt, rd, funct;
    wire [5:0]  imm;
    wire [11:0] jump_addr;
    wire        reg_dst, alu_src, mem_to_reg, reg_write;
    wire        mem_read, mem_write, branch, jump;
    wire [3:0]  alu_op;

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

    assign opcode    = instruction[15:12];
    assign rs        = instruction[11:9];
    assign rt        = instruction[8:6];
    assign rd        = instruction[5:3];
    assign funct     = instruction[2:0];
    assign imm       = instruction[5:0];
    assign jump_addr = instruction[11:0];

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1;
        #12;
        rst = 0;

        repeat (50) begin
            @(posedge clk);
            $display("Time: %0t | PC: %h | Inst: %h | Opcode: %b | RS: %d | RT: %d | RD: %d | Funct: %b | Imm: %h | ALU_Res: %h | RD1: %h | RD2: %h | WD: %h | Zero: %b | WReg: %d",
                     $time, pc_out, instruction, opcode, rs, rt, rd, funct, imm, alu_result, read_data1, read_data2, write_data, zero_flag, write_reg);
        end
        $finish;
    end

    initial begin
        $dumpfile("output/waveform_detailed.vcd");
        $dumpvars(0, mips16_tb_detailed);
    end

endmodule