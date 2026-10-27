`timescale 1ns / 1ps
// =============================================================================
// File        : FPMM.v
// Project     : 4x4 Fixed-Point Matrix Multiplication (OpenLane SKY130 Target)
// Description : Top-Level 4x4 Q7.8 Fixed-Point Matrix Multiplier
//               - Loads 4x4 Matrix A and Matrix B over 16 clock cycles (S_LOAD)
//               - Computes all 16 dot products in parallel via 64 qmult + 48 qadd
//               - Writes 16 Q7.8 product results to matrix_out RAM over 16 cycles
//               - Streams registered 16-bit results out on data_out[15:0]
// =============================================================================
`default_nettype none

module matrix_multiplication (
    input  wire        clk,
    input  wire        reset,
    output wire [15:0] data_out
);

    // Input and output format for 16-bit Q7.8 fixed point:
    // | [15] Sign (1 bit) | [14:8] Integer (7 bits) | [7:0] Fraction (8 bits) |
    wire [15:0] mat_A;
    wire [15:0] mat_B;

    // Per-cell overflow wires (fixes multi-driver synthesis conflict in original RTL)
    wire overflow1 [0:3][0:3];
    wire overflow2 [0:3][0:3];
    wire overflow3 [0:3][0:3];
    wire overflow4 [0:3][0:3];

    reg         wen;
    reg  [15:0] data_in;
    reg  [3:0]  addr;
    reg         load_done;
    reg  [4:0]  address;
    reg  [3:0]  wr_addr;
    reg         write_done;

    reg  [15:0] matrixA [0:3][0:3];
    reg  [15:0] matrixB [0:3][0:3];

    wire [15:0] tmp1 [0:3][0:3];
    wire [15:0] tmp2 [0:3][0:3];
    wire [15:0] tmp3 [0:3][0:3];
    wire [15:0] tmp4 [0:3][0:3];
    wire [15:0] tmp5 [0:3][0:3];
    wire [15:0] tmp6 [0:3][0:3];
    wire [15:0] tmp7 [0:3][0:3];

    // Input ROMs for Matrix A and Matrix B
    Matrix_A matrix_A_u (
        .clka  (clk),
        .addra (addr),
        .douta (mat_A)
    );

    ROM matrix_B_u (
        .clka  (clk),
        .addra (addr),
        .douta (mat_B)
    );

    // -------------------------------------------------------------------------
    // Phase 1: Sequential Load of 4x4 Matrix A and Matrix B (16 Clock Cycles)
    // -------------------------------------------------------------------------
    integer r, c;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            addr      <= 4'd0;
            load_done <= 1'b0;
            for (r = 0; r < 4; r = r + 1) begin
                for (c = 0; c < 4; c = c + 1) begin
                    matrixA[r][c] <= 16'h0000;
                    matrixB[r][c] <= 16'h0000;
                end
            end
        end else if (!load_done) begin
            matrixA[addr[3:2]][addr[1:0]] <= mat_A;
            matrixB[addr[3:2]][addr[1:0]] <= mat_B;
            if (addr < 4'd15) begin
                addr <= addr + 4'd1;
            end else begin
                load_done <= 1'b1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Parallel 4x4 Q7.8 Fixed-Point Matrix Multiplication Array
    // 16 dot-product engines x (4 qmult + 3 qadd) = 64 Multipliers, 48 Adders
    // -------------------------------------------------------------------------
    genvar i, j;
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen1
            for (j = 0; j < 4; j = j + 1) begin : gen2
                qmult #(8, 16) mult_u1 (
                    .i_multiplicand (matrixA[i][0]),
                    .i_multiplier   (matrixB[0][j]),
                    .o_result       (tmp1[i][j]),
                    .ovr            (overflow1[i][j])
                );
                qmult #(8, 16) mult_u2 (
                    .i_multiplicand (matrixA[i][1]),
                    .i_multiplier   (matrixB[1][j]),
                    .o_result       (tmp2[i][j]),
                    .ovr            (overflow2[i][j])
                );
                qmult #(8, 16) mult_u3 (
                    .i_multiplicand (matrixA[i][2]),
                    .i_multiplier   (matrixB[2][j]),
                    .o_result       (tmp3[i][j]),
                    .ovr            (overflow3[i][j])
                );
                qmult #(8, 16) mult_u4 (
                    .i_multiplicand (matrixA[i][3]),
                    .i_multiplier   (matrixB[3][j]),
                    .o_result       (tmp4[i][j]),
                    .ovr            (overflow4[i][j])
                );

                qadd #(8, 16) Add_u1 (
                    .a (tmp1[i][j]),
                    .b (tmp2[i][j]),
                    .c (tmp5[i][j])
                );
                qadd #(8, 16) Add_u2 (
                    .a (tmp3[i][j]),
                    .b (tmp4[i][j]),
                    .c (tmp6[i][j])
                );
                qadd #(8, 16) Add_u3 (
                    .a (tmp5[i][j]),
                    .b (tmp6[i][j]),
                    .c (tmp7[i][j])
                );
            end
        end
    endgenerate

    // -------------------------------------------------------------------------
    // Phase 2 & 3: Write 16 Products to matrix_out RAM, then Stream Readout
    // -------------------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            address    <= 5'd0;
            wr_addr    <= 4'd0;
            wen        <= 1'b0;
            write_done <= 1'b0;
            data_in    <= 16'h0000;
        end else if (!load_done) begin
            address    <= 5'd0;
            wr_addr    <= 4'd0;
            wen        <= 1'b0;
            write_done <= 1'b0;
            data_in    <= 16'h0000;
        end else begin
            address <= address + 5'd1;
            wr_addr <= address[3:0];
            if (!write_done) begin
                wen     <= 1'b1;
                data_in <= tmp7[address[3:2]][address[1:0]];
                if (address[3:0] == 4'd15) begin
                    write_done <= 1'b1;
                end
            end else begin
                wen <= 1'b0;
            end
        end
    end

    wire [3:0] ram_addr = wen ? wr_addr : address[3:0];

    matrix_out matrix_out_u (
        .clka  (clk),
        .addra (ram_addr),
        .douta (data_out),
        .wea   (wen),
        .dina  (data_in)
    );

endmodule
`default_nettype wire
