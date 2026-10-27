// =============================================================================
// File        : rv32i_lsu.v
// Project     : RV32IM + Zicsr 5-Stage Pipelined SoC (OpenLane SKY130 Target)
// Description : Load/Store Alignment Unit (MEM Stage)
// =============================================================================
`default_nettype none

module rv32i_lsu (
    input  wire [1:0]  addr_offset,
    input  wire [2:0]  funct3,
    input  wire        mem_write,
    input  wire [31:0] rs2_data,
    input  wire [31:0] dmem_rdata,
    output reg  [3:0]  dmem_wstrb,
    output reg  [31:0] dmem_wdata,
    output reg  [31:0] load_data
);

    always @(*) begin
        dmem_wstrb = 4'b0000;
        dmem_wdata = rs2_data;
        if (mem_write) begin
            case (funct3)
                3'b000: begin // SB
                    dmem_wstrb = 4'b0001 << addr_offset;
                    dmem_wdata = {4{rs2_data[7:0]}};
                end
                3'b001: begin // SH
                    dmem_wstrb = addr_offset[1] ? 4'b1100 : 4'b0011;
                    dmem_wdata = {2{rs2_data[15:0]}};
                end
                3'b010: begin // SW
                    dmem_wstrb = 4'b1111;
                    dmem_wdata = rs2_data;
                end
                default: begin
                    dmem_wstrb = 4'b0000;
                    dmem_wdata = rs2_data;
                end
            endcase
        end
    end

    reg [7:0]  selected_byte;
    reg [15:0] selected_half;

    always @(*) begin
        case (addr_offset)
            2'b00: selected_byte = dmem_rdata[7:0];
            2'b01: selected_byte = dmem_rdata[15:8];
            2'b10: selected_byte = dmem_rdata[23:16];
            2'b11: selected_byte = dmem_rdata[31:24];
        endcase

        selected_half = addr_offset[1] ? dmem_rdata[31:16] : dmem_rdata[15:0];

        case (funct3)
            3'b000: load_data = {{24{selected_byte[7]}}, selected_byte}; // LB
            3'b001: load_data = {{16{selected_half[15]}}, selected_half}; // LH
            3'b010: load_data = dmem_rdata;                              // LW
            3'b100: load_data = {24'b0, selected_byte};                  // LBU
            3'b101: load_data = {16'b0, selected_half};                  // LHU
            default: load_data = dmem_rdata;
        endcase
    end

endmodule
`default_nettype wire
