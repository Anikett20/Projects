// =============================================================================
// File        : rv32i_hazard_unit.v
// Project     : RV32IM + Zicsr 5-Stage Pipelined SoC (OpenLane SKY130 Target)
// Description : Pipeline Hazard Detection & Control Unit supporting:
//               - Multi-cycle MDU busy stall (`mdu_busy`)
//               - Load-Use hazard 1-cycle stall
//               - Taken Branch / Jump / Trap / MRET pipeline flush
// =============================================================================
`default_nettype none

module rv32i_hazard_unit (
    input  wire [4:0] id_rs1_addr,
    input  wire [4:0] id_rs2_addr,
    input  wire       ex_mem_read,
    input  wire [4:0] ex_rd_addr,
    input  wire       ex_pc_redirect,
    input  wire       mdu_busy,
    output wire       pc_en,
    output wire       if_id_en,
    output wire       id_ex_en,
    output wire       if_id_flush,
    output wire       id_ex_flush,
    output wire       ex_mem_flush
);

    wire load_use_hazard = ex_mem_read && (ex_rd_addr != 5'd0) &&
                           ((ex_rd_addr == id_rs1_addr) || (ex_rd_addr == id_rs2_addr));

    assign pc_en        = ~(load_use_hazard | mdu_busy);
    assign if_id_en     = ~(load_use_hazard | mdu_busy);
    assign id_ex_en     = ~mdu_busy;

    assign if_id_flush  = ex_pc_redirect & ~mdu_busy;
    assign id_ex_flush  = (ex_pc_redirect | load_use_hazard) & ~mdu_busy;
    assign ex_mem_flush = mdu_busy;

endmodule
`default_nettype wire
