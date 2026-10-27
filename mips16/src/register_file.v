`timescale 1ns / 1ps
`default_nettype none

module register_file (
    input  wire        clk,
    input  wire        rst,
    input  wire        reg_write,
    input  wire [2:0]  read_reg1,
    input  wire [2:0]  read_reg2,
    input  wire [2:0]  write_reg,
    input  wire [15:0] write_data,
    output wire [15:0] read_data1,
    output wire [15:0] read_data2
);

    reg [15:0] registers [0:7];

    assign read_data1 = (read_reg1 == 3'b000) ? 16'h0000 : registers[read_reg1];
    assign read_data2 = (read_reg2 == 3'b000) ? 16'h0000 : registers[read_reg2];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            registers[0] <= 16'h0000;
            registers[1] <= 16'h0000;
            registers[2] <= 16'h0000;
            registers[3] <= 16'h0000;
            registers[4] <= 16'h0000;
            registers[5] <= 16'h0000;
            registers[6] <= 16'h0000;
            registers[7] <= 16'h0000;
        end else if (reg_write && write_reg != 3'b000) begin
            registers[write_reg] <= write_data;
        end
    end

endmodule
`default_nettype wire
