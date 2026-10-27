// =============================================================================
// File        : rv32im_gpio_timer.v
// Project     : RV32IM + Zicsr 5-Stage Pipelined SoC (OpenLane SKY130 Target)
// Description : Memory-Mapped 32-Bit GPIO & CLINT Timer/Comparator Peripheral
// =============================================================================
`default_nettype none
`include "rv32i_defs.vh"

module rv32im_gpio_timer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        reg_we,
    input  wire [7:0]  reg_addr,
    input  wire [31:0] reg_wdata,
    output reg  [31:0] reg_rdata,
    output reg  [31:0] gpio_out,
    input  wire [31:0] gpio_in,
    output wire        irq_timer
);

    reg [31:0] timer_cnt;
    reg [31:0] timer_cmp;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gpio_out  <= 32'h0000_0000;
            timer_cnt <= 32'h0000_0000;
            timer_cmp <= 32'hFFFF_FFFF;
        end else begin
            timer_cnt <= timer_cnt + 32'd1;

            if (reg_we) begin
                case (reg_addr)
                    `MMIO_GPIO_OUT:  gpio_out  <= reg_wdata;
                    `MMIO_TIMER_CNT: timer_cnt <= reg_wdata;
                    `MMIO_TIMER_CMP: timer_cmp <= reg_wdata;
                    default: ;
                endcase
            end
        end
    end

    always @(*) begin
        case (reg_addr)
            `MMIO_GPIO_OUT:  reg_rdata = gpio_out;
            `MMIO_GPIO_IN:   reg_rdata = gpio_in;
            `MMIO_TIMER_CNT: reg_rdata = timer_cnt;
            `MMIO_TIMER_CMP: reg_rdata = timer_cmp;
            default:         reg_rdata = 32'h0000_0000;
        endcase
    end

    assign irq_timer = (timer_cnt >= timer_cmp);

endmodule
`default_nettype wire
