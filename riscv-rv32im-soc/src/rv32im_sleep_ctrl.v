// =============================================================================
// File        : rv32im_sleep_ctrl.v
// Project     : RV32IM + Zicsr 5-Stage Pipelined SoC (OpenLane SKY130 Target)
// Description : Hardware Clock-Enable & WFI (Wait-for-Interrupt) Sleep Controller
//               - Uses synchronous enable-based clock gating (icg_en) on the
//                 single always-on clk domain (zero CDC races in sim & STA)
//               - Waits 2 drain cycles in SLEEP_WFI_WAIT so older instructions
//                 in MEM (e.g., SW to TIMER_CMP) and WB complete cleanly
//               - Wakes immediately on irq_timer OR irq_uart when global_mie=1
// =============================================================================
`default_nettype none
`include "rv32i_defs.vh"

module rv32im_sleep_ctrl (
    input  wire       clk,           // Always-on system clock
    input  wire       rst_n,

    // Clock gate enable output to CPU core (1 = running, 0 = gated/sleeping)
    output reg        icg_en,

    // WFI request from core EX stage (high when WFI is in EX and no IRQ taken)
    input  wire       wfi_request,

    // Wake sources from always-on peripherals
    input  wire       irq_timer,
    input  wire       irq_uart,

    // Global interrupt enable from CSR (mstatus.MIE)
    input  wire       global_mie,

    // Sleep status outputs for debug / pins
    output wire       sleep_active,
    output wire       wake_pending
);

    // Pure Verilog-2005 state encodings (Yosys read_verilog compatible)
    localparam [1:0] SLEEP_IDLE     = 2'd0; // Normal operation (icg_en = 1)
    localparam [1:0] SLEEP_WFI_WAIT = 2'd1; // Draining MEM & WB stages (icg_en = 1)
    localparam [1:0] SLEEP_DEEP     = 2'd2; // Core pipeline gated (icg_en = 0)
    localparam [1:0] SLEEP_WAKE     = 2'd3; // Wake detected, releasing gate (icg_en = 1)

    reg [1:0] state;
    reg [1:0] state_next;
    reg [1:0] wait_cnt;

    wire wake_timer = irq_timer & global_mie;
    wire wake_uart  = irq_uart  & global_mie;
    wire any_wake   = wake_timer | wake_uart;

    always @(*) begin
        state_next = state;
        case (state)
            SLEEP_IDLE: begin
                if (wfi_request && !any_wake)
                    state_next = SLEEP_WFI_WAIT;
            end

            SLEEP_WFI_WAIT: begin
                if (any_wake)
                    state_next = SLEEP_IDLE;
                else if (wait_cnt == 2'd2)
                    state_next = SLEEP_DEEP;
            end

            SLEEP_DEEP: begin
                if (any_wake)
                    state_next = SLEEP_WAKE;
            end

            SLEEP_WAKE: begin
                state_next = SLEEP_IDLE;
            end

            default: state_next = SLEEP_IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= SLEEP_IDLE;
            icg_en   <= 1'b1;
            wait_cnt <= 2'd0;
        end else begin
            state <= state_next;
            case (state_next)
                SLEEP_IDLE: begin
                    icg_en   <= 1'b1;
                    wait_cnt <= 2'd0;
                end
                SLEEP_WFI_WAIT: begin
                    icg_en   <= 1'b1;
                    wait_cnt <= wait_cnt + 2'd1;
                end
                SLEEP_DEEP: begin
                    icg_en   <= 1'b0;
                    wait_cnt <= 2'd0;
                end
                SLEEP_WAKE: begin
                    icg_en   <= 1'b1;
                    wait_cnt <= 2'd0;
                end
                default: begin
                    icg_en   <= 1'b1;
                    wait_cnt <= 2'd0;
                end
            endcase
        end
    end

    assign sleep_active = (state == SLEEP_DEEP);
    assign wake_pending = any_wake;

endmodule
`default_nettype wire
