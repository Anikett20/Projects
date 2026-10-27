// =============================================================================
// File        : rv32im_uart.v
// Project     : RV32IM + Zicsr 5-Stage Pipelined SoC (OpenLane SKY130 Target)
// Description : Memory-Mapped 16550-Style UART with TX/RX Shifters & Interrupt
// =============================================================================
`default_nettype none
`include "rv32i_defs.vh"

module rv32im_uart (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        reg_we,
    input  wire        reg_re,
    input  wire [7:0]  reg_addr,
    input  wire [31:0] reg_wdata,
    output reg  [31:0] reg_rdata,
    output wire        uart_txd,
    input  wire        uart_rxd,
    output wire        irq_uart,
    output reg         tx_byte_done,
    output reg  [7:0]  tx_byte_latched
);

    reg [15:0] baud_div;
    reg [15:0] baud_cnt;
    wire       baud_tick = (baud_cnt == 16'd0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_div <= 16'd2;
            baud_cnt <= 16'd0;
        end else begin
            if (reg_we && reg_addr == `MMIO_UART_BAUD) begin
                baud_div <= reg_wdata[15:0];
                baud_cnt <= reg_wdata[15:0];
            end else if (baud_cnt == 16'd0) begin
                baud_cnt <= baud_div;
            end else begin
                baud_cnt <= baud_cnt - 16'd1;
            end
        end
    end

    reg       tx_busy;
    reg [3:0] tx_bit_cnt;
    reg [9:0] tx_shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_busy         <= 1'b0;
            tx_bit_cnt      <= 4'd0;
            tx_shift_reg    <= 10'h3FF;
            tx_byte_done    <= 1'b0;
            tx_byte_latched <= 8'h00;
        end else begin
            tx_byte_done <= 1'b0;
            if (!tx_busy && reg_we && reg_addr == `MMIO_UART_TXDATA) begin
                tx_busy         <= 1'b1;
                tx_bit_cnt      <= 4'd10;
                tx_shift_reg    <= {1'b1, reg_wdata[7:0], 1'b0};
                tx_byte_latched <= reg_wdata[7:0];
            end else if (tx_busy && baud_tick) begin
                tx_shift_reg <= {1'b1, tx_shift_reg[9:1]};
                tx_bit_cnt   <= tx_bit_cnt - 4'd1;
                if (tx_bit_cnt == 4'd1) begin
                    tx_busy      <= 1'b0;
                    tx_byte_done <= 1'b1;
                end
            end
        end
    end

    assign uart_txd = tx_shift_reg[0];

    // 2-Stage RX Synchronizer & Shift Register
    reg       rx_sync1, rx_sync2;
    reg [3:0] rx_bit_cnt;
    reg [9:0] rx_shift_reg;
    reg       rx_busy;
    reg [7:0] rx_fifo_data;
    reg       rx_fifo_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync1      <= 1'b1;
            rx_sync2      <= 1'b1;
            rx_busy       <= 1'b0;
            rx_bit_cnt    <= 4'd0;
            rx_shift_reg  <= 10'h0;
            rx_fifo_data  <= 8'h0;
            rx_fifo_valid <= 1'b0;
        end else begin
            rx_sync1 <= uart_rxd;
            rx_sync2 <= rx_sync1;

            if (!rx_busy && rx_sync2 && !rx_sync1) begin
                rx_busy    <= 1'b1;
                rx_bit_cnt <= 4'd10;
            end else if (rx_busy && baud_tick) begin
                rx_shift_reg <= {rx_sync2, rx_shift_reg[9:1]};
                rx_bit_cnt   <= rx_bit_cnt - 4'd1;
                if (rx_bit_cnt == 4'd1) begin
                    rx_busy       <= 1'b0;
                    rx_fifo_data  <= rx_shift_reg[8:1];
                    rx_fifo_valid <= 1'b1;
                end
            end

            if (reg_re && reg_addr == `MMIO_UART_TXDATA) begin
                rx_fifo_valid <= 1'b0;
            end
        end
    end

    always @(*) begin
        case (reg_addr)
            `MMIO_UART_TXDATA: reg_rdata = {24'h0, rx_fifo_data};
            `MMIO_UART_STATUS: reg_rdata = {30'h0, rx_fifo_valid, tx_busy};
            `MMIO_UART_BAUD:   reg_rdata = {16'h0, baud_div};
            default:           reg_rdata = 32'h0;
        endcase
    end

    assign irq_uart = rx_fifo_valid;

endmodule
`default_nettype wire
