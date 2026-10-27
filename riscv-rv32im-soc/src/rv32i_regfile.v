// =============================================================================
// File        : rv32i_regfile.v
// Project     : RV32IM + Zicsr 5-Stage Pipelined SoC (OpenLane SKY130 Target)
// Description : 32x32-bit Register File with internal Write-First Bypass
// =============================================================================
`default_nettype none

module rv32i_regfile (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        we,
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    input  wire [4:0]  rd_addr,
    input  wire [31:0] rd_wdata,
    output wire [31:0] rs1_rdata,
    output wire [31:0] rs2_rdata
);

    reg [31:0] regs [1:31];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 1; i < 32; i = i + 1) begin
                regs[i] <= 32'h0000_0000;
            end
        end else if (we && (rd_addr != 5'd0)) begin
            regs[rd_addr] <= rd_wdata;
        end
    end

    assign rs1_rdata = (rs1_addr == 5'd0) ? 32'h0000_0000 :
                       (we && (rd_addr == rs1_addr)) ? rd_wdata : regs[rs1_addr];

    assign rs2_rdata = (rs2_addr == 5'd0) ? 32'h0000_0000 :
                       (we && (rd_addr == rs2_addr)) ? rd_wdata : regs[rs2_addr];

endmodule
`default_nettype wire
