// =============================================================================
// File        : rv32im_spi.v
// Project     : RV32IM + Zicsr 5-Stage Pipelined SoC (OpenLane SKY130 Target)
// Description : SPI Master Controller with configurable CPOL/CPHA,
//               8/16/32-bit transfers, TX/RX FIFOs, and interrupt support.
//               MMIO Base: 0x1000_0030 (per rv32i_defs.vh)
// =============================================================================
`default_nettype none
`include "rv32i_defs.vh"

module rv32im_spi (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        reg_we,
    input  wire        reg_re,
    input  wire [7:0]  reg_addr,
    input  wire [31:0] reg_wdata,
    output reg  [31:0] reg_rdata,

    // SPI Physical Pins
    output wire        spi_sck,
    output wire        spi_mosi,
    input  wire        spi_miso,
    output wire        spi_cs_n,

    // Interrupt
    output wire        irq_spi
);

    // ------------------------------------------------------------
    // Register Map (matches core_bus_addr[7:0] from rv32i_defs.vh)
    // ------------------------------------------------------------
    localparam [7:0] SPI_CTRL   = `MMIO_SPI_CTRL;    // 8'h30
    localparam [7:0] SPI_CLKDIV = `MMIO_SPI_CLKDIV;  // 8'h34
    localparam [7:0] SPI_TXDATA = `MMIO_SPI_TXDATA;  // 8'h38
    localparam [7:0] SPI_STATUS = `MMIO_SPI_STATUS;  // 8'h3C
    localparam [7:0] SPI_CS     = `MMIO_SPI_CS;      // 8'h40
    localparam [7:0] SPI_IRQ_EN = `MMIO_SPI_IRQ_EN;  // 8'h44

    reg        ctrl_en;
    reg        ctrl_cpol;
    reg        ctrl_cpha;
    reg        ctrl_lsb_first;
    reg [1:0]  ctrl_dwidth;
    reg [15:0] clkdiv;
    reg [3:0]  cs_reg;
    reg        irq_en_tx_empty;
    reg        irq_en_rx_full;
    reg        irq_en_done;

    reg [15:0] sck_cnt;
    reg        sck_int;

    // TX FIFO (4 entries x 32-bit)
    reg [31:0] tx_fifo [0:3];
    reg [1:0]  tx_wr_ptr, tx_rd_ptr;
    wire       tx_full  = ((tx_wr_ptr + 2'd1) == tx_rd_ptr);
    wire       tx_empty = (tx_wr_ptr == tx_rd_ptr);

    // RX FIFO (4 entries x 32-bit)
    reg [31:0] rx_fifo [0:3];
    reg [1:0]  rx_wr_ptr, rx_rd_ptr;
    wire       rx_full  = ((rx_wr_ptr + 2'd1) == rx_rd_ptr);
    wire       rx_empty = (rx_wr_ptr == rx_rd_ptr);

    // Pure Verilog-2005 state encodings (Yosys read_verilog compatible)
    localparam [2:0] SPI_IDLE  = 3'd0;
    localparam [2:0] SPI_SETUP = 3'd1;
    localparam [2:0] SPI_SHIFT = 3'd2;
    localparam [2:0] SPI_HOLD  = 3'd3;
    localparam [2:0] SPI_DONE  = 3'd4;

    reg [2:0]  spi_state;
    reg [5:0]  bit_cnt;
    reg [5:0]  total_bits;
    reg [31:0] tx_shift_reg;
    reg [31:0] rx_shift_reg;
    reg        sck_prev;
    wire       sck_posedge =  sck_int & ~sck_prev;
    wire       sck_negedge = ~sck_int &  sck_prev;
    wire       sample_edge = ctrl_cpha ? sck_negedge : sck_posedge;
    wire       shift_edge  = ctrl_cpha ? sck_posedge : sck_negedge;
    reg        cs_active;
    reg [3:0]  cs_select;
    reg        done_flag;

    wire [31:0] next_tx_word = tx_fifo[tx_rd_ptr];
    wire [31:0] aligned_tx_word = ctrl_lsb_first ? next_tx_word :
                                  (ctrl_dwidth == 2'b00) ? {next_tx_word[7:0],  24'd0} :
                                  (ctrl_dwidth == 2'b01) ? {next_tx_word[15:0], 16'd0} :
                                                           next_tx_word;

    // SCK generator
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sck_cnt  <= 16'd0;
            sck_int  <= 1'b0;
            sck_prev <= 1'b0;
        end else begin
            sck_prev <= sck_int;
            if (spi_state == SPI_SHIFT) begin
                if (sck_cnt == 16'd0) begin
                    sck_int <= ~sck_int;
                    sck_cnt <= clkdiv;
                end else begin
                    sck_cnt <= sck_cnt - 16'd1;
                end
            end else begin
                sck_int <= ctrl_cpol;
                sck_cnt <= clkdiv;
            end
        end
    end

    // SPI State Machine & FIFOs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_state       <= SPI_IDLE;
            bit_cnt         <= 6'd0;
            total_bits      <= 6'd8;
            tx_shift_reg    <= 32'd0;
            rx_shift_reg    <= 32'd0;
            cs_active       <= 1'b0;
            cs_select       <= 4'hE;
            done_flag       <= 1'b0;
            tx_wr_ptr       <= 2'd0;
            tx_rd_ptr       <= 2'd0;
            rx_wr_ptr       <= 2'd0;
            rx_rd_ptr       <= 2'd0;
            tx_fifo[0]      <= 32'd0;
            tx_fifo[1]      <= 32'd0;
            tx_fifo[2]      <= 32'd0;
            tx_fifo[3]      <= 32'd0;
            rx_fifo[0]      <= 32'd0;
            rx_fifo[1]      <= 32'd0;
            rx_fifo[2]      <= 32'd0;
            rx_fifo[3]      <= 32'd0;
            ctrl_en         <= 1'b0;
            ctrl_cpol       <= 1'b0;
            ctrl_cpha       <= 1'b0;
            ctrl_lsb_first  <= 1'b0;
            ctrl_dwidth     <= 2'b00;
            clkdiv          <= 16'd1;
            cs_reg          <= 4'hE;
            irq_en_tx_empty <= 1'b0;
            irq_en_rx_full  <= 1'b0;
            irq_en_done     <= 1'b0;
        end else begin
            if (reg_we) begin
                case (reg_addr)
                    SPI_CTRL: begin
                        ctrl_en        <= reg_wdata[0];
                        ctrl_cpol      <= reg_wdata[1];
                        ctrl_cpha      <= reg_wdata[2];
                        ctrl_lsb_first <= reg_wdata[3];
                        ctrl_dwidth    <= reg_wdata[5:4];
                    end
                    SPI_CLKDIV: clkdiv <= reg_wdata[15:0];
                    SPI_CS:     cs_reg <= reg_wdata[3:0];
                    SPI_IRQ_EN: begin
                        irq_en_tx_empty <= reg_wdata[0];
                        irq_en_rx_full  <= reg_wdata[1];
                        irq_en_done     <= reg_wdata[2];
                    end
                    SPI_TXDATA: begin
                        if (!tx_full) begin
                            tx_fifo[tx_wr_ptr] <= reg_wdata;
                            tx_wr_ptr          <= tx_wr_ptr + 2'd1;
                        end
                    end
                    default: ;
                endcase
            end

            if (reg_re && (reg_addr == SPI_TXDATA)) begin
                if (!rx_empty) begin
                    rx_rd_ptr <= rx_rd_ptr + 2'd1;
                end
            end

            case (spi_state)
                SPI_IDLE: begin
                    cs_active <= 1'b0;
                    cs_select <= cs_reg;
                    if (ctrl_en && !tx_empty) begin
                        tx_shift_reg <= aligned_tx_word;
                        case (ctrl_dwidth)
                            2'b00:   total_bits <= 6'd8;
                            2'b01:   total_bits <= 6'd16;
                            2'b10:   total_bits <= 6'd32;
                            default: total_bits <= 6'd8;
                        endcase
                        bit_cnt      <= 6'd0;
                        rx_shift_reg <= 32'd0;
                        cs_active    <= 1'b1;
                        done_flag    <= 1'b0;
                        spi_state    <= SPI_SETUP;
                    end
                end

                SPI_SETUP: begin
                    spi_state <= SPI_SHIFT;
                end

                SPI_SHIFT: begin
                    if (sample_edge) begin
                        if (ctrl_lsb_first)
                            rx_shift_reg <= {spi_miso, rx_shift_reg[31:1]};
                        else
                            rx_shift_reg <= {rx_shift_reg[30:0], spi_miso};
                    end

                    if (shift_edge) begin
                        if (ctrl_lsb_first)
                            tx_shift_reg <= {1'b0, tx_shift_reg[31:1]};
                        else
                            tx_shift_reg <= {tx_shift_reg[30:0], 1'b0};

                        if ((bit_cnt + 6'd1) >= total_bits) begin
                            spi_state <= SPI_HOLD;
                        end
                        bit_cnt <= bit_cnt + 6'd1;
                    end
                end

                SPI_HOLD: begin
                    cs_active <= 1'b0;
                    if (!rx_full) begin
                        rx_fifo[rx_wr_ptr] <= rx_shift_reg;
                        rx_wr_ptr          <= rx_wr_ptr + 2'd1;
                    end
                    tx_rd_ptr <= tx_rd_ptr + 2'd1;
                    done_flag <= 1'b1;
                    spi_state <= SPI_DONE;
                end

                SPI_DONE: begin
                    spi_state <= SPI_IDLE;
                end

                default: spi_state <= SPI_IDLE;
            endcase
        end
    end

    assign spi_sck  = (spi_state == SPI_SHIFT) ? sck_int : ctrl_cpol;
    assign spi_mosi = cs_active ? (ctrl_lsb_first ? tx_shift_reg[0] : tx_shift_reg[31]) : 1'b0;
    assign spi_cs_n = ~cs_active;

    always @(*) begin
        case (reg_addr)
            SPI_CTRL:   reg_rdata = {26'd0, ctrl_dwidth, ctrl_lsb_first, ctrl_cpha, ctrl_cpol, ctrl_en};
            SPI_CLKDIV: reg_rdata = {16'd0, clkdiv};
            SPI_TXDATA: reg_rdata = rx_empty ? 32'd0 : rx_fifo[rx_rd_ptr];
            SPI_STATUS: reg_rdata = {28'd0, done_flag, ~rx_empty, ~tx_full, (spi_state != SPI_IDLE)};
            SPI_CS:     reg_rdata = {28'd0, cs_reg};
            SPI_IRQ_EN: reg_rdata = {29'd0, irq_en_done, irq_en_rx_full, irq_en_tx_empty};
            default:    reg_rdata = 32'd0;
        endcase
    end

    assign irq_spi = (irq_en_tx_empty & ~tx_full) |
                     (irq_en_rx_full  & ~rx_empty) |
                     (irq_en_done     & done_flag);

endmodule
`default_nettype wire
