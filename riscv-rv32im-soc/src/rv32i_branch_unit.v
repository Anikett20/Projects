// =============================================================================
// File        : rv32i_branch_unit.v
// Project     : RV32IM + Zicsr 5-Stage Pipelined SoC (OpenLane SKY130 Target)
// Description : Evaluates BEQ, BNE, BLT, BGE, BLTU, BGEU in the EX stage
// =============================================================================
`default_nettype none

module rv32i_branch_unit (
    input  wire [31:0] rs1_data,
    input  wire [31:0] rs2_data,
    input  wire [2:0]  funct3,
    input  wire        is_branch,
    output reg         branch_taken
);

    wire eq   = (rs1_data == rs2_data);
    wire lt   = ($signed(rs1_data) < $signed(rs2_data));
    wire ltu  = (rs1_data < rs2_data);

    always @(*) begin
        if (!is_branch) begin
            branch_taken = 1'b0;
        end else begin
            case (funct3)
                3'b000: branch_taken =  eq;  // BEQ
                3'b001: branch_taken = ~eq;  // BNE
                3'b100: branch_taken =  lt;  // BLT
                3'b101: branch_taken = ~lt;  // BGE
                3'b110: branch_taken =  ltu; // BLTU
                3'b111: branch_taken = ~ltu; // BGEU
                default: branch_taken = 1'b0;
            endcase
        end
    end

endmodule
`default_nettype wire
