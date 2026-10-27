// =============================================================================
// File        : rv32i_forwarding_unit.v
// Project     : RV32IM + Zicsr 5-Stage Pipelined SoC (OpenLane SKY130 Target)
// Description : Resolves Read-After-Write (RAW) Data Hazards in EX stage
// =============================================================================
`default_nettype none
`include "rv32i_defs.vh"

module rv32i_forwarding_unit (
    input  wire [4:0] ex_rs1_addr,
    input  wire [4:0] ex_rs2_addr,
    input  wire       mem_reg_we,
    input  wire [4:0] mem_rd_addr,
    input  wire       wb_reg_we,
    input  wire [4:0] wb_rd_addr,
    output reg  [1:0] fwd_a_sel,
    output reg  [1:0] fwd_b_sel
);

    always @(*) begin
        if (mem_reg_we && (mem_rd_addr != 5'd0) && (mem_rd_addr == ex_rs1_addr)) begin
            fwd_a_sel = `FWD_MEM;
        end else if (wb_reg_we && (wb_rd_addr != 5'd0) && (wb_rd_addr == ex_rs1_addr)) begin
            fwd_a_sel = `FWD_WB;
        end else begin
            fwd_a_sel = `FWD_NONE;
        end
    end

    always @(*) begin
        if (mem_reg_we && (mem_rd_addr != 5'd0) && (mem_rd_addr == ex_rs2_addr)) begin
            fwd_b_sel = `FWD_MEM;
        end else if (wb_reg_we && (wb_rd_addr != 5'd0) && (wb_rd_addr == ex_rs2_addr)) begin
            fwd_b_sel = `FWD_WB;
        end else begin
            fwd_b_sel = `FWD_NONE;
        end
    end

endmodule
`default_nettype wire
