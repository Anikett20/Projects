// =============================================================================
// File        : rv32im_mdu.v
// Project     : RV32IM + Zicsr 5-Stage Pipelined SoC (OpenLane SKY130 Target)
// Description : Bug-Fixed 32-Cycle Iterative Multiply/Divide Unit (RV32M)
//               - Uses iterative shift-and-add for 64-bit MUL/MULH/MULHSU/MULHU
//                 (eliminates the 3,600-gate combinational multiplier tree and
//                 fixes the upper-32-bit MULH/MULHSU/MULHU calculation)
//               - Uses 32-cycle restoring division with proper dividend bit
//                 shifting and RISC-V spec divide-by-zero & overflow handling.
// =============================================================================
`default_nettype none
`include "rv32i_defs.vh"

module rv32im_mdu (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid,
    input  wire [2:0]  funct3,
    input  wire [31:0] op_a,
    input  wire [31:0] op_b,
    output wire        busy,
    output reg         done,
    output reg  [31:0] result
);

    localparam STATE_IDLE = 2'd0;
    localparam STATE_RUN  = 2'd1;
    localparam STATE_DONE = 2'd2;

    reg [1:0]  state;
    reg [5:0]  step_cnt;
    reg [2:0]  op_reg;
    reg        is_div_reg;
    reg        neg_out_reg;
    reg        div_by_zero_reg;
    reg        div_ovf_reg;
    reg [31:0] raw_a_reg;

    reg [63:0] acc;
    reg [63:0] mcand;
    reg [31:0] mplier;
    reg [31:0] rem_reg;
    reg [31:0] quot_reg;
    reg [31:0] div_b_reg;

    wire is_div      = funct3[2];
    wire a_is_signed = (funct3 == `MDU_MULH)   || (funct3 == `MDU_MULHSU) ||
                       (funct3 == `MDU_DIV)    || (funct3 == `MDU_REM);
    wire b_is_signed = (funct3 == `MDU_MULH)   ||
                       (funct3 == `MDU_DIV)    || (funct3 == `MDU_REM);

    wire a_neg = a_is_signed & op_a[31];
    wire b_neg = b_is_signed & op_b[31];

    wire [31:0] abs_a = a_neg ? (~op_a + 32'd1) : op_a;
    wire [31:0] abs_b = b_neg ? (~op_b + 32'd1) : op_b;

    wire [32:0] rem_shift = {rem_reg[30:0], mplier[31]};
    wire [32:0] rem_sub   = rem_shift - {1'b0, div_b_reg};
    wire [63:0] signed_prod = neg_out_reg ? (~acc + 64'd1) : acc;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= STATE_IDLE;
            step_cnt        <= 6'd0;
            op_reg          <= 3'd0;
            is_div_reg      <= 1'b0;
            neg_out_reg     <= 1'b0;
            div_by_zero_reg <= 1'b0;
            div_ovf_reg     <= 1'b0;
            raw_a_reg       <= 32'd0;
            acc             <= 64'd0;
            mcand           <= 64'd0;
            mplier          <= 32'd0;
            rem_reg         <= 32'd0;
            quot_reg        <= 32'd0;
            div_b_reg       <= 32'd0;
            done            <= 1'b0;
            result          <= 32'd0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    done <= 1'b0;
                    if (valid) begin
                        op_reg          <= funct3;
                        is_div_reg      <= is_div;
                        raw_a_reg       <= op_a;
                        div_by_zero_reg <= (op_b == 32'd0);
                        div_ovf_reg     <= (op_a == 32'h8000_0000) && (op_b == 32'hFFFF_FFFF) &&
                                           ((funct3 == `MDU_DIV) || (funct3 == `MDU_REM));

                        if (funct3 == `MDU_REM)
                            neg_out_reg <= a_neg;
                        else
                            neg_out_reg <= a_neg ^ b_neg;

                        acc       <= 64'd0;
                        mcand     <= {32'd0, abs_a};
                        mplier    <= is_div ? abs_a : abs_b;
                        rem_reg   <= 32'd0;
                        quot_reg  <= 32'd0;
                        div_b_reg <= abs_b;
                        step_cnt  <= 6'd32;
                        state     <= STATE_RUN;
                    end
                end

                STATE_RUN: begin
                    if (step_cnt > 6'd0) begin
                        if (!is_div_reg) begin
                            if (mplier[0])
                                acc <= acc + mcand;
                            mcand  <= mcand << 1;
                            mplier <= mplier >> 1;
                        end else begin
                            if (!rem_sub[32]) begin
                                rem_reg  <= rem_sub[31:0];
                                quot_reg <= {quot_reg[30:0], 1'b1};
                            end else begin
                                rem_reg  <= rem_shift[31:0];
                                quot_reg <= {quot_reg[30:0], 1'b0};
                            end
                            mplier <= {mplier[30:0], 1'b0};
                        end
                        step_cnt <= step_cnt - 6'd1;
                    end else begin
                        state <= STATE_DONE;
                        done  <= 1'b1;
                        if (!is_div_reg) begin
                            if (op_reg == `MDU_MUL)
                                result <= signed_prod[31:0];
                            else
                                result <= signed_prod[63:32];
                        end else begin
                            if (div_by_zero_reg) begin
                                result <= (op_reg == `MDU_DIV || op_reg == `MDU_DIVU) ? 32'hFFFF_FFFF : raw_a_reg;
                            end else if (div_ovf_reg) begin
                                result <= (op_reg == `MDU_DIV) ? 32'h8000_0000 : 32'h0000_0000;
                            end else if (op_reg == `MDU_DIV || op_reg == `MDU_DIVU) begin
                                result <= neg_out_reg ? (~quot_reg + 32'd1) : quot_reg;
                            end else begin
                                result <= neg_out_reg ? (~rem_reg + 32'd1) : rem_reg;
                            end
                        end
                    end
                end

                STATE_DONE: begin
                    done  <= 1'b0;
                    state <= STATE_IDLE;
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end

    assign busy = (valid && (state == STATE_IDLE)) || (state == STATE_RUN);

endmodule
`default_nettype wire
