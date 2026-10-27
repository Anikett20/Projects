// =============================================================================
// File        : rv32im_csr.v
// Project     : RV32IM + Zicsr 5-Stage Pipelined SoC (OpenLane SKY130 Target)
// Description : Machine-Mode Control & Status Register (Zicsr) Unit and
//               Prioritized Interrupt/Trap Controller (CLINT/External).
//               Supports mstatus, mie, mtvec, mscratch, mepc, mcause, mip,
//               mcycle, minstret, ECALL, EBREAK, MRET, and WFI.
// =============================================================================
`default_nettype none
`include "rv32i_defs.vh"

module rv32im_csr (
    input  wire        clk,
    input  wire        icg_en,
    input  wire        rst_n,

    // EX Stage CSR Access Interface
    input  wire        csr_en,
    input  wire [2:0]  csr_op,
    input  wire [11:0] csr_addr,
    input  wire [31:0] csr_wdata,
    output reg  [31:0] csr_rdata,

    // Trap / Exception / Return Requests from EX Stage
    input  wire [31:0] ex_pc,
    input  wire        is_ecall,
    input  wire        is_ebreak,
    input  wire        is_mret,
    input  wire        is_wfi,
    input  wire        inst_retired,

    // Hardware Interrupt Lines from SoC Peripherals
    input  wire        irq_timer,
    input  wire        irq_uart,

    // Trap / Return PC Redirect Outputs
    output wire        trap_taken,
    output wire        mret_taken,
    output wire [31:0] trap_target_pc,
    output wire        irq_taken,

    // WFI Sleep Request Output (to Sleep Controller)
    output wire        wfi_sleep_request,
    // Global MIE (mstatus[3]) for Sleep Controller wake detection
    output wire        global_mie
);

    reg [31:0] mstatus;   // Bit 3: MIE, Bit 7: MPIE
    reg [31:0] mie;       // Bit 7: MTIE (Timer), Bit 11: MEIE (External/UART)
    reg [31:0] mtvec;     // Trap Vector Base Address
    reg [31:0] mscratch;  // Machine Scratch Register
    reg [31:0] mepc;      // Machine Exception PC
    reg [31:0] mcause;    // Machine Trap Cause
    reg [31:0] mcycle;    // Cycle Counter (always-on clk)
    reg [31:0] minstret;  // Instructions Retired Counter
    reg [31:0] wfi_pc_reg; // Captured WFI PC for exact mepc on wake

    wire [31:0] mip = {20'd0, irq_uart, 3'd0, irq_timer, 7'd0};

    // Pending enabled interrupts (trigger when ex_pc != 0 or waking from WFI)
    wire global_mie_int = mstatus[3];
    wire pending_uart   = irq_uart  & mie[11];
    wire pending_tmr    = irq_timer & mie[7];
    wire has_valid_pc   = (ex_pc != 32'd0) || (wfi_pc_reg != 32'd0);
    wire irq_take       = global_mie_int & (pending_uart | pending_tmr) & has_valid_pc;

    // Use WFI PC for mepc when waking from WFI sleep
    wire [31:0] mepc_val = (irq_take && (wfi_pc_reg != 32'd0)) ? wfi_pc_reg : ex_pc;

    assign trap_taken        = irq_take | is_ecall | is_ebreak;
    assign mret_taken        = is_mret;
    assign trap_target_pc    = is_mret ? mepc : mtvec;
    assign irq_taken         = irq_take;
    assign wfi_sleep_request = is_wfi & ~irq_take;
    assign global_mie        = mstatus[3];

    // Capture WFI PC when WFI enters EX stage; clear when interrupt trap is taken
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wfi_pc_reg <= 32'd0;
        end else if (icg_en) begin
            if (irq_take) begin
                wfi_pc_reg <= 32'd0;
            end else if (is_wfi) begin
                wfi_pc_reg <= ex_pc;
            end
        end
    end

    // CSR Read Multiplexer
    always @(*) begin
        case (csr_addr)
            `CSR_MSTATUS:  csr_rdata = mstatus | 32'h0000_1800;
            `CSR_MIE:      csr_rdata = mie;
            `CSR_MTVEC:    csr_rdata = mtvec;
            `CSR_MSCRATCH: csr_rdata = mscratch;
            `CSR_MEPC:     csr_rdata = mepc;
            `CSR_MCAUSE:   csr_rdata = mcause;
            `CSR_MIP:      csr_rdata = mip;
            `CSR_MCYCLE:   csr_rdata = mcycle;
            `CSR_MINSTRET: csr_rdata = minstret;
            default:       csr_rdata = 32'h0000_0000;
        endcase
    end

    // CSR Write Value Computation (CSRRW/RWI, CSRRS/RSI, CSRRC/RCI)
    reg [31:0] csr_next_val;
    always @(*) begin
        case (csr_op)
            `CSR_RW, `CSR_RWI: csr_next_val = csr_wdata;
            `CSR_RS, `CSR_RSI: csr_next_val = csr_rdata | csr_wdata;
            `CSR_RC, `CSR_RCI: csr_next_val = csr_rdata & ~csr_wdata;
            default:           csr_next_val = csr_rdata;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mstatus  <= 32'h0000_0000;
            mie      <= 32'h0000_0000;
            mtvec    <= 32'h0000_0000;
            mscratch <= 32'h0000_0000;
            mepc     <= 32'h0000_0000;
            mcause   <= 32'h0000_0000;
            mcycle   <= 32'h0000_0000;
            minstret <= 32'h0000_0000;
        end else begin
            mcycle <= mcycle + 32'd1;

            if (icg_en) begin
                if (inst_retired)
                    minstret <= minstret + 32'd1;

                if (trap_taken) begin
                    mepc    <= mepc_val;
                    mstatus <= {mstatus[31:8], mstatus[3], mstatus[6:4], 1'b0, mstatus[2:0]};
                    if (pending_uart && global_mie_int)
                        mcause <= 32'h8000_000B; // Machine External Interrupt (UART)
                    else if (pending_tmr && global_mie_int)
                        mcause <= 32'h8000_0007; // Machine Timer Interrupt
                    else if (is_ecall)
                        mcause <= 32'h0000_000B; // Environment Call from M-mode
                    else
                        mcause <= 32'h0000_0003; // Breakpoint (EBREAK)
                end else if (is_mret) begin
                    mstatus <= {mstatus[31:8], 1'b1, mstatus[6:4], mstatus[7], mstatus[2:0]};
                end else if (csr_en) begin
                    case (csr_addr)
                        `CSR_MSTATUS:  mstatus  <= csr_next_val;
                        `CSR_MIE:      mie      <= csr_next_val;
                        `CSR_MTVEC:    mtvec    <= {csr_next_val[31:2], 2'b00};
                        `CSR_MSCRATCH: mscratch <= csr_next_val;
                        `CSR_MEPC:     mepc     <= {csr_next_val[31:2], 2'b00};
                        `CSR_MCAUSE:   mcause   <= csr_next_val;
                        default: ;
                    endcase
                end
            end
        end
    end

endmodule
`default_nettype wire
