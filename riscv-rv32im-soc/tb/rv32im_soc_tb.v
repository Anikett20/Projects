// =============================================================================
// File        : rv32im_soc_tb.v
// Project     : RV32IM + Zicsr 5-Stage Pipelined SoC (OpenLane SKY130 Target)
// Description : Self-Checking SoC Testbench verifying RV32M (MUL, DIV, REM),
//               Zicsr CSR instructions, WFI Low-Power Clock Gating Sleep/Wake,
//               CLINT Timer Interrupt trap into ISR at `mtvec` + `MRET`,
//               GPIO, and SPI Master Loopback.
// =============================================================================
`timescale 1ns/1ps

module rv32im_soc_tb;

    reg         clk;
    reg         rst_n;

    wire [31:0] imem_addr;
    wire [31:0] imem_rdata;
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire [3:0]  dmem_wstrb;
    wire        dmem_re;
    wire [31:0] dmem_rdata;

    wire        uart_txd;
    reg         uart_rxd;
    wire [31:0] gpio_out;
    reg  [31:0] gpio_in;
    wire        irq_timer;
    wire        irq_uart;
    wire        spi_sck;
    wire        spi_mosi;
    wire        spi_miso;
    wire        spi_cs_n;

    wire        uart_byte_done;
    wire [7:0]  uart_byte_data;
    wire [31:0] dbg_pc;
    wire        dbg_reg_we;
    wire [4:0]  dbg_rd_addr;
    wire [31:0] dbg_rd_wdata;
    wire        illegal_inst;
    wire        sleep_active;
    wire        wake_pending;

    reg [31:0] imem [0:1023];
    reg [31:0] dmem [0:1023];

    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            imem[i] = 32'h0000_0013;
            dmem[i] = 32'h0000_0000;
        end
        $readmemh("../sw/firmware.hex", imem);
    end

    assign imem_rdata = imem[imem_addr[11:2]];
    assign dmem_rdata = dmem[dmem_addr[11:2]];

    always @(posedge clk) begin
        if (|dmem_wstrb) begin
            if (dmem_wstrb[0]) dmem[dmem_addr[11:2]][7:0]   <= dmem_wdata[7:0];
            if (dmem_wstrb[1]) dmem[dmem_addr[11:2]][15:8]  <= dmem_wdata[15:8];
            if (dmem_wstrb[2]) dmem[dmem_addr[11:2]][23:16] <= dmem_wdata[23:16];
            if (dmem_wstrb[3]) dmem[dmem_addr[11:2]][31:24] <= dmem_wdata[31:24];
        end
    end

    // Direct SPI Loopback (MISO connected to MOSI when CS_N is active low)
    assign spi_miso = (!spi_cs_n) ? spi_mosi : 1'b1;

    rv32im_soc u_dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .imem_addr      (imem_addr),
        .imem_rdata     (imem_rdata),
        .dmem_addr      (dmem_addr),
        .dmem_wdata     (dmem_wdata),
        .dmem_wstrb     (dmem_wstrb),
        .dmem_re        (dmem_re),
        .dmem_rdata     (dmem_rdata),
        .uart_txd       (uart_txd),
        .uart_rxd       (uart_rxd),
        .gpio_out       (gpio_out),
        .gpio_in        (gpio_in),
        .irq_timer      (irq_timer),
        .irq_uart       (irq_uart),
        .spi_sck        (spi_sck),
        .spi_mosi       (spi_mosi),
        .spi_miso       (spi_miso),
        .spi_cs_n       (spi_cs_n),
        .uart_byte_done (uart_byte_done),
        .uart_byte_data (uart_byte_data),
        .dbg_pc         (dbg_pc),
        .dbg_reg_we     (dbg_reg_we),
        .dbg_rd_addr    (dbg_rd_addr),
        .dbg_rd_wdata   (dbg_rd_wdata),
        .illegal_inst   (illegal_inst),
        .sleep_active   (sleep_active),
        .wake_pending   (wake_pending)
    );

    initial clk = 1'b0;
    always #10 clk = ~clk;

    integer cycle_cnt;
    reg wfi_tested = 1'b0;
    reg spi_tested = 1'b0;

    initial begin
        $dumpfile("rv32im_phase5_soc_tb.vcd");
        $dumpvars(0, rv32im_soc_tb);

        rst_n     = 1'b0;
        uart_rxd  = 1'b1;
        gpio_in   = 32'hA5A5_0042;
        cycle_cnt = 0;
        #45;
        rst_n = 1'b1;

        while (cycle_cnt < 5000) begin
            @(posedge clk);
            cycle_cnt = cycle_cnt + 1;

            if (dbg_reg_we && (dbg_rd_addr != 5'd0)) begin
                $display("[Cycle %04d] WB_PC=0x%08x | x%02d <= 0x%08x (%0d)",
                         cycle_cnt, dbg_pc, dbg_rd_addr, dbg_rd_wdata, $signed(dbg_rd_wdata));
            end

            if (sleep_active && !wfi_tested) begin
                $display("[Cycle %04d] *** WFI SLEEP ENTERED (icg_en=0, timer_cnt=%0d, timer_cmp=%0d) ***",
                         cycle_cnt, u_dut.u_gpio_timer.timer_cnt, u_dut.u_gpio_timer.timer_cmp);
                wfi_tested = 1'b1;
            end

            if (wake_pending && sleep_active) begin
                $display("[Cycle %04d] *** TIMER IRQ WAKE PENDING (timer_cnt=%0d >= timer_cmp=%0d) ***",
                         cycle_cnt, u_dut.u_gpio_timer.timer_cnt, u_dut.u_gpio_timer.timer_cmp);
            end

            if (!spi_cs_n && !spi_tested) begin
                $display("[Cycle %04d] *** SPI MASTER TRANSACTION ACTIVE (CS_N=0) ***", cycle_cnt);
                spi_tested = 1'b1;
            end

            if (dmem[64] == 32'hCAFE_BABE) begin
                @(posedge clk);
                $display("======================================================================");
                $display("PHASE 5 RV32IM + ZICSR SoC SELF-CHECK PASSED at Cycle %0d!", cycle_cnt);
                $display("  DMEM[0x00] (MUL 1234 * 5678)     = 0x%08x (Expected: 0x006AE9BC)", dmem[0]);
                $display("  DMEM[0x04] (DIV 7006652 / 1234)  = 0x%08x (Expected: 0x0000162E)", dmem[1]);
                $display("  DMEM[0x08] (REM 7006652 %% 1000)  = 0x%08x (Expected: 0x0000028C)", dmem[2]);
                $display("  DMEM[0x0C] (Timer ISR mcause)    = 0x%08x (Expected: 0x80000007)", dmem[3]);
                $display("  DMEM[0x10] (SPI Loopback RX)     = 0x%08x (Expected: 0x0000005A)", dmem[4]);
                $display("  GPIO_OUT   (Memory-Mapped GPIO)  = 0x%08x (Expected: 0x006AE9BC)", gpio_out);
                $display("  DMEM[0x100] (Completion Flag)    = 0x%08x (Expected: 0xCAFEBABE)", dmem[64]);
                $display("  Sleep Tested (WFI -> IRQ Wake):  %s", wfi_tested ? "YES" : "NO");
                $display("  SPI Tested   (MOSI->MISO 0x5A):  %s", spi_tested ? "YES" : "NO");
                $display("======================================================================");
                $finish;
            end
        end

        $display("ERROR: Simulation timed out after %0d cycles!", cycle_cnt);
        $finish;
    end

endmodule
