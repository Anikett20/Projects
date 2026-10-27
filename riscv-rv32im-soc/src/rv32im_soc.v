// =============================================================================
// File        : rv32im_soc.v
// Project     : RV32IM + Zicsr 5-Stage Pipelined SoC (OpenLane SKY130 Target)
// Description : Top-Level Synthesizable RV32IM + Zicsr Microcontroller SoC
//               Exposes external Harvard IMEM & DMEM buses:
//               - 5-Stage Pipelined RV32IM + Zicsr Core (`rv32i_core`)
//               - 16550-Compatible UART TX/RX (`rv32im_uart`)
//               - 32-Bit GPIO & CLINT Timer (`rv32im_gpio_timer`)
//               - SPI Master Controller (`rv32im_spi`)
//               - Hardware Clock-Enable & WFI Sleep Controller (`rv32im_sleep_ctrl`)
// =============================================================================
`default_nettype none
`include "rv32i_defs.vh"

module rv32im_soc (
    input  wire        clk,
    input  wire        rst_n,

    // External Instruction SRAM Bus
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_rdata,

    // External Data SRAM Bus (`0x0000_xxxx`)
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire [3:0]  dmem_wstrb,
    output wire        dmem_re,
    input  wire [31:0] dmem_rdata,

    // Microcontroller Physical I/O Pins
    output wire        uart_txd,
    input  wire        uart_rxd,
    output wire [31:0] gpio_out,
    input  wire [31:0] gpio_in,
    output wire        irq_timer,
    output wire        irq_uart,
    output wire        spi_sck,
    output wire        spi_mosi,
    input  wire        spi_miso,
    output wire        spi_cs_n,

    // Verification / Debug Trace Outputs
    output wire        uart_byte_done,
    output wire [7:0]  uart_byte_data,
    output wire [31:0] dbg_pc,
    output wire        dbg_reg_we,
    output wire [4:0]  dbg_rd_addr,
    output wire [31:0] dbg_rd_wdata,
    output wire        illegal_inst,
    output wire        sleep_active,
    output wire        wake_pending
);

    wire [31:0] core_bus_addr;
    wire [31:0] core_bus_wdata;
    wire [3:0]  core_bus_wstrb;
    wire        core_bus_re;
    wire [31:0] core_bus_rdata;

    wire is_mmio    = (core_bus_addr[31:16] == `MMIO_BASE_PREFIX);
    wire is_uart    = is_mmio && (core_bus_addr[7:4] == 4'h0);
    wire is_gpio_tm = is_mmio && ((core_bus_addr[7:4] == 4'h1) || (core_bus_addr[7:4] == 4'h2));
    wire is_spi     = is_mmio && ((core_bus_addr[7:4] == 4'h3) || (core_bus_addr[7:4] == 4'h4));
    wire mmio_we    = is_mmio && (|core_bus_wstrb);

    assign dmem_addr  = core_bus_addr;
    assign dmem_wdata = core_bus_wdata;
    assign dmem_wstrb = is_mmio ? 4'b0000 : core_bus_wstrb;
    assign dmem_re    = is_mmio ? 1'b0    : core_bus_re;

    wire [31:0] uart_rdata;
    wire [31:0] gpio_timer_rdata;
    wire [31:0] spi_rdata;
    wire        irq_spi_unused;

    assign core_bus_rdata = is_uart    ? uart_rdata       :
                            is_gpio_tm ? gpio_timer_rdata :
                            is_spi     ? spi_rdata        :
                                         dmem_rdata;

    rv32im_uart u_uart (
        .clk             (clk),
        .rst_n           (rst_n),
        .reg_we          (mmio_we & is_uart),
        .reg_re          (core_bus_re & is_uart),
        .reg_addr        (core_bus_addr[7:0]),
        .reg_wdata       (core_bus_wdata),
        .reg_rdata       (uart_rdata),
        .uart_txd        (uart_txd),
        .uart_rxd        (uart_rxd),
        .irq_uart        (irq_uart),
        .tx_byte_done    (uart_byte_done),
        .tx_byte_latched (uart_byte_data)
    );

    rv32im_gpio_timer u_gpio_timer (
        .clk       (clk),
        .rst_n     (rst_n),
        .reg_we    (mmio_we & is_gpio_tm),
        .reg_addr  (core_bus_addr[7:0]),
        .reg_wdata (core_bus_wdata),
        .reg_rdata (gpio_timer_rdata),
        .gpio_out  (gpio_out),
        .gpio_in   (gpio_in),
        .irq_timer (irq_timer)
    );

    rv32im_spi u_spi (
        .clk       (clk),
        .rst_n     (rst_n),
        .reg_we    (mmio_we & is_spi),
        .reg_re    (core_bus_re & is_spi),
        .reg_addr  (core_bus_addr[7:0]),
        .reg_wdata (core_bus_wdata),
        .reg_rdata (spi_rdata),
        .spi_sck   (spi_sck),
        .spi_mosi  (spi_mosi),
        .spi_miso  (spi_miso),
        .spi_cs_n  (spi_cs_n),
        .irq_spi   (irq_spi_unused)
    );

    wire icg_en;
    wire wfi_sleep_request;
    wire global_mie;

    rv32im_sleep_ctrl u_sleep_ctrl (
        .clk          (clk),
        .rst_n        (rst_n),
        .icg_en       (icg_en),
        .wfi_request  (wfi_sleep_request),
        .irq_timer    (irq_timer),
        .irq_uart     (irq_uart),
        .global_mie   (global_mie),
        .sleep_active (sleep_active),
        .wake_pending (wake_pending)
    );

    rv32i_core u_core (
        .clk               (clk),
        .icg_en            (icg_en),
        .rst_n             (rst_n),
        .imem_addr         (imem_addr),
        .imem_rdata        (imem_rdata),
        .dmem_addr         (core_bus_addr),
        .dmem_wdata        (core_bus_wdata),
        .dmem_wstrb        (core_bus_wstrb),
        .dmem_re           (core_bus_re),
        .dmem_rdata        (core_bus_rdata),
        .irq_timer         (irq_timer),
        .irq_uart          (irq_uart),
        .dbg_pc            (dbg_pc),
        .dbg_reg_we        (dbg_reg_we),
        .dbg_rd_addr       (dbg_rd_addr),
        .dbg_rd_wdata      (dbg_rd_wdata),
        .illegal_inst      (illegal_inst),
        .wfi_sleep_request (wfi_sleep_request),
        .global_mie        (global_mie)
    );

endmodule
`default_nettype wire
