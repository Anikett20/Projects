// =============================================================================
// File        : rv32i_core.v
// Project     : RV32IM + Zicsr 5-Stage Pipelined SoC (OpenLane SKY130 Target)
// Description : 5-Stage Pipelined RV32IM + Zicsr CPU Core (IF-ID-EX-MEM-WB)
//               integrating the 32-cycle Iterative MDU, Zicsr CSR & Trap Unit,
//               Data Forwarding, Hazard Detection, and Enable-Based Clock Gating.
// =============================================================================
`default_nettype none
`include "rv32i_defs.vh"

module rv32i_core (
    input  wire        clk,           // Always-on system clock
    input  wire        icg_en,        // Clock gate enable from sleep_ctrl (1=run, 0=sleep)
    input  wire        rst_n,

    // Instruction Memory Interface (IF Stage)
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_rdata,

    // Data Memory / MMIO Bus Interface (MEM Stage)
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire [3:0]  dmem_wstrb,
    output wire        dmem_re,
    input  wire [31:0] dmem_rdata,

    // Hardware Interrupt Inputs from SoC Peripherals
    input  wire        irq_timer,
    input  wire        irq_uart,

    // Debug / Verification Trace Port (WB Stage Retirement)
    output wire [31:0] dbg_pc,
    output wire        dbg_reg_we,
    output wire [4:0]  dbg_rd_addr,
    output wire [31:0] dbg_rd_wdata,
    output wire        illegal_inst,

    // WFI Sleep Request Output (to Sleep Controller)
    output wire        wfi_sleep_request,
    // Global MIE (mstatus[3]) for Sleep Controller wake detection
    output wire        global_mie
);

    wire        pc_en;
    wire        if_id_en;
    wire        id_ex_en;
    wire        if_id_flush;
    wire        id_ex_flush;
    wire        ex_mem_flush;
    wire        ex_pc_redirect;
    wire [31:0] ex_redirect_target;
    wire        mdu_busy;
    wire        wfi_sleep_request_int;
    wire        global_mie_int;
    wire        irq_taken;

    // =========================================================================
    // STAGE 1: INSTRUCTION FETCH (IF)
    // =========================================================================
    reg  [31:0] if_pc;
    wire [31:0] if_pc_plus_4 = if_pc + 32'd4;
    wire [31:0] if_pc_next   = ex_pc_redirect ? ex_redirect_target : if_pc_plus_4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            if_pc <= 32'h0000_0000;
        end else if (icg_en) begin
            if (ex_pc_redirect && !mdu_busy) begin
                if_pc <= ex_redirect_target;
            end else if (pc_en && !wfi_sleep_request_int) begin
                if_pc <= if_pc_plus_4;
            end
        end
    end

    assign imem_addr = if_pc;

    // =========================================================================
    // PIPELINE REGISTER: IF / ID
    // =========================================================================
    reg [31:0] id_pc;
    reg [31:0] id_pc_plus_4;
    reg [31:0] id_inst;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            id_pc        <= 32'h0000_0000;
            id_pc_plus_4 <= 32'h0000_0004;
            id_inst      <= `INST_NOP;
        end else if (icg_en) begin
            if (if_id_flush) begin
                id_pc        <= 32'h0000_0000;
                id_pc_plus_4 <= 32'h0000_0000;
                id_inst      <= `INST_NOP;
            end else if (if_id_en && !wfi_sleep_request_int) begin
                id_pc        <= if_pc;
                id_pc_plus_4 <= if_pc_plus_4;
                id_inst      <= imem_rdata;
            end
        end
    end

    // =========================================================================
    // STAGE 2: INSTRUCTION DECODE & REGISTER FILE READ (ID)
    // =========================================================================
    wire [4:0]  id_rd       = id_inst[11:7];
    wire [2:0]  id_funct3   = id_inst[14:12];
    wire [4:0]  id_rs1      = id_inst[19:15];
    wire [4:0]  id_rs2      = id_inst[24:20];
    wire [11:0] id_csr_addr = id_inst[31:20];

    wire       id_reg_we;
    wire [2:0] id_imm_sel;
    wire       id_alu_src_a_pc;
    wire       id_alu_src_b_imm;
    wire [3:0] id_alu_op;
    wire       id_is_mdu;
    wire       id_is_branch;
    wire       id_is_jal;
    wire       id_is_jalr;
    wire       id_mem_read;
    wire       id_mem_write;
    wire [1:0] id_wb_sel;
    wire       id_csr_en;
    wire       id_is_ecall;
    wire       id_is_ebreak;
    wire       id_is_mret;
    wire       id_is_wfi;
    wire       id_illegal_inst;

    rv32i_decoder u_decoder (
        .inst          (id_inst),
        .reg_we        (id_reg_we),
        .imm_sel       (id_imm_sel),
        .alu_src_a_pc  (id_alu_src_a_pc),
        .alu_src_b_imm (id_alu_src_b_imm),
        .alu_op        (id_alu_op),
        .is_mdu        (id_is_mdu),
        .is_branch     (id_is_branch),
        .is_jal        (id_is_jal),
        .is_jalr       (id_is_jalr),
        .mem_read      (id_mem_read),
        .mem_write     (id_mem_write),
        .wb_sel        (id_wb_sel),
        .csr_en        (id_csr_en),
        .is_ecall      (id_is_ecall),
        .is_ebreak     (id_is_ebreak),
        .is_mret       (id_is_mret),
        .is_wfi        (id_is_wfi),
        .illegal_inst  (id_illegal_inst)
    );

    wire [31:0] id_imm;
    rv32i_imm_gen u_imm_gen (
        .inst    (id_inst),
        .imm_sel (id_imm_sel),
        .imm_out (id_imm)
    );

    reg         wb_reg_we;
    reg  [4:0]  wb_rd_addr;
    reg  [31:0] wb_rd_wdata;

    wire [31:0] id_rs1_data;
    wire [31:0] id_rs2_data;

    rv32i_regfile u_regfile (
        .clk       (clk),
        .rst_n     (rst_n),
        .we        (wb_reg_we & icg_en),
        .rs1_addr  (id_rs1),
        .rs2_addr  (id_rs2),
        .rd_addr   (wb_rd_addr),
        .rd_wdata  (wb_rd_wdata),
        .rs1_rdata (id_rs1_data),
        .rs2_rdata (id_rs2_data)
    );

    // =========================================================================
    // PIPELINE REGISTER: ID / EX
    // =========================================================================
    reg [31:0] ex_pc;
    reg [31:0] ex_pc_plus_4;
    reg [31:0] ex_rs1_data;
    reg [31:0] ex_rs2_data;
    reg [31:0] ex_imm;
    reg [4:0]  ex_rs1_addr;
    reg [4:0]  ex_rs2_addr;
    reg [4:0]  ex_rd_addr;
    reg [2:0]  ex_funct3;
    reg [11:0] ex_csr_addr;
    reg        ex_reg_we;
    reg        ex_alu_src_a_pc;
    reg        ex_alu_src_b_imm;
    reg [3:0]  ex_alu_op;
    reg        ex_is_mdu;
    reg        ex_is_branch;
    reg        ex_is_jal;
    reg        ex_is_jalr;
    reg        ex_mem_read;
    reg        ex_mem_write;
    reg [1:0]  ex_wb_sel;
    reg        ex_csr_en;
    reg        ex_is_ecall;
    reg        ex_is_ebreak;
    reg        ex_is_mret;
    reg        ex_is_wfi;
    reg        ex_illegal_inst;

    reg [31:0] ex_rs1_forwarded;
    reg [31:0] ex_rs2_forwarded;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_pc            <= 32'h0000_0000;
            ex_pc_plus_4     <= 32'h0000_0000;
            ex_rs1_data      <= 32'h0000_0000;
            ex_rs2_data      <= 32'h0000_0000;
            ex_imm           <= 32'h0000_0000;
            ex_rs1_addr      <= 5'd0;
            ex_rs2_addr      <= 5'd0;
            ex_rd_addr       <= 5'd0;
            ex_funct3        <= 3'b000;
            ex_csr_addr      <= 12'h000;
            ex_reg_we        <= 1'b0;
            ex_alu_src_a_pc  <= 1'b0;
            ex_alu_src_b_imm <= 1'b0;
            ex_alu_op        <= `ALU_ADD;
            ex_is_mdu        <= 1'b0;
            ex_is_branch     <= 1'b0;
            ex_is_jal        <= 1'b0;
            ex_is_jalr       <= 1'b0;
            ex_mem_read      <= 1'b0;
            ex_mem_write     <= 1'b0;
            ex_wb_sel        <= `WB_ALU;
            ex_csr_en        <= 1'b0;
            ex_is_ecall      <= 1'b0;
            ex_is_ebreak     <= 1'b0;
            ex_is_mret       <= 1'b0;
            ex_is_wfi        <= 1'b0;
            ex_illegal_inst  <= 1'b0;
        end else if (icg_en) begin
            if (id_ex_flush) begin
                ex_pc            <= 32'h0000_0000;
                ex_pc_plus_4     <= 32'h0000_0000;
                ex_rs1_data      <= 32'h0000_0000;
                ex_rs2_data      <= 32'h0000_0000;
                ex_imm           <= 32'h0000_0000;
                ex_rs1_addr      <= 5'd0;
                ex_rs2_addr      <= 5'd0;
                ex_rd_addr       <= 5'd0;
                ex_funct3        <= 3'b000;
                ex_csr_addr      <= 12'h000;
                ex_reg_we        <= 1'b0;
                ex_alu_src_a_pc  <= 1'b0;
                ex_alu_src_b_imm <= 1'b0;
                ex_alu_op        <= `ALU_ADD;
                ex_is_mdu        <= 1'b0;
                ex_is_branch     <= 1'b0;
                ex_is_jal        <= 1'b0;
                ex_is_jalr       <= 1'b0;
                ex_mem_read      <= 1'b0;
                ex_mem_write     <= 1'b0;
                ex_wb_sel        <= `WB_ALU;
                ex_csr_en        <= 1'b0;
                ex_is_ecall      <= 1'b0;
                ex_is_ebreak     <= 1'b0;
                ex_is_mret       <= 1'b0;
                ex_is_wfi        <= 1'b0;
                ex_illegal_inst  <= 1'b0;
            end else if (wfi_sleep_request_int) begin
                // Hold WFI instruction in EX while MEM and WB finish draining
                ex_pc <= ex_pc;
            end else if (id_ex_en) begin
                ex_pc            <= id_pc;
                ex_pc_plus_4     <= id_pc_plus_4;
                ex_rs1_data      <= id_rs1_data;
                ex_rs2_data      <= id_rs2_data;
                ex_imm           <= id_imm;
                ex_rs1_addr      <= id_rs1;
                ex_rs2_addr      <= id_rs2;
                ex_rd_addr       <= id_rd;
                ex_funct3        <= id_funct3;
                ex_csr_addr      <= id_csr_addr;
                ex_reg_we        <= id_reg_we;
                ex_alu_src_a_pc  <= id_alu_src_a_pc;
                ex_alu_src_b_imm <= id_alu_src_b_imm;
                ex_alu_op        <= id_alu_op;
                ex_is_mdu        <= id_is_mdu;
                ex_is_branch     <= id_is_branch;
                ex_is_jal        <= id_is_jal;
                ex_is_jalr       <= id_is_jalr;
                ex_mem_read      <= id_mem_read;
                ex_mem_write     <= id_mem_write;
                ex_wb_sel        <= id_wb_sel;
                ex_csr_en        <= id_csr_en;
                ex_is_ecall      <= id_is_ecall;
                ex_is_ebreak     <= id_is_ebreak;
                ex_is_mret       <= id_is_mret;
                ex_is_wfi        <= id_is_wfi;
                ex_illegal_inst  <= id_illegal_inst;
            end else begin
                ex_rs1_data      <= ex_rs1_forwarded;
                ex_rs2_data      <= ex_rs2_forwarded;
                ex_rs1_addr      <= 5'd0;
                ex_rs2_addr      <= 5'd0;
            end
        end
    end

    // =========================================================================
    // STAGE 3: EXECUTE (ALU + RV32M MDU + ZICSR/TRAP + FORWARDING + BRANCH)
    // =========================================================================
    reg         mem_reg_we;
    reg  [4:0]  mem_rd_addr;
    wire [31:0] mem_fwd_value;

    wire [1:0]  fwd_a_sel;
    wire [1:0]  fwd_b_sel;

    rv32i_forwarding_unit u_forwarding_unit (
        .ex_rs1_addr (ex_rs1_addr),
        .ex_rs2_addr (ex_rs2_addr),
        .mem_reg_we  (mem_reg_we),
        .mem_rd_addr (mem_rd_addr),
        .wb_reg_we   (wb_reg_we),
        .wb_rd_addr  (wb_rd_addr),
        .fwd_a_sel   (fwd_a_sel),
        .fwd_b_sel   (fwd_b_sel)
    );

    always @(*) begin
        case (fwd_a_sel)
            `FWD_MEM:  ex_rs1_forwarded = mem_fwd_value;
            `FWD_WB:   ex_rs1_forwarded = wb_rd_wdata;
            default:   ex_rs1_forwarded = ex_rs1_data;
        endcase

        case (fwd_b_sel)
            `FWD_MEM:  ex_rs2_forwarded = mem_fwd_value;
            `FWD_WB:   ex_rs2_forwarded = wb_rd_wdata;
            default:   ex_rs2_forwarded = ex_rs2_data;
        endcase
    end

    wire [31:0] ex_alu_in_a = ex_alu_src_a_pc  ? ex_pc  : ex_rs1_forwarded;
    wire [31:0] ex_alu_in_b = ex_alu_src_b_imm ? ex_imm : ex_rs2_forwarded;
    wire [31:0] ex_alu_only_result;

    rv32i_alu u_alu (
        .a      (ex_alu_in_a),
        .b      (ex_alu_in_b),
        .alu_op (ex_alu_op),
        .result (ex_alu_only_result)
    );

    // RV32M Multiply/Divide Unit
    wire        mdu_done;
    wire [31:0] mdu_result;
    wire        mdu_valid = ex_is_mdu & ~mdu_done & icg_en;

    rv32im_mdu u_mdu (
        .clk    (clk),
        .rst_n  (rst_n),
        .valid  (mdu_valid),
        .funct3 (ex_funct3),
        .op_a   (ex_rs1_forwarded),
        .op_b   (ex_rs2_forwarded),
        .busy   (mdu_busy),
        .done   (mdu_done),
        .result (mdu_result)
    );

    // Machine-Mode CSR & Interrupt/Trap Unit
    wire [31:0] csr_wdata_in = ex_funct3[2] ? {27'd0, ex_rs1_addr} : ex_rs1_forwarded;
    wire [31:0] ex_csr_rdata;
    wire        trap_taken;
    wire        mret_taken;
    wire [31:0] trap_target_pc;

    rv32im_csr u_csr (
        .clk               (clk),
        .icg_en            (icg_en),
        .rst_n             (rst_n),
        .csr_en            (ex_csr_en),
        .csr_op            (ex_funct3),
        .csr_addr          (ex_csr_addr),
        .csr_wdata         (csr_wdata_in),
        .csr_rdata         (ex_csr_rdata),
        .ex_pc             (ex_pc),
        .is_ecall          (ex_is_ecall),
        .is_ebreak         (ex_is_ebreak),
        .is_mret           (ex_is_mret),
        .is_wfi            (ex_is_wfi),
        .inst_retired      (wb_reg_we),
        .irq_timer         (irq_timer),
        .irq_uart          (irq_uart),
        .trap_taken        (trap_taken),
        .mret_taken        (mret_taken),
        .trap_target_pc    (trap_target_pc),
        .irq_taken         (irq_taken),
        .wfi_sleep_request (wfi_sleep_request_int),
        .global_mie        (global_mie_int)
    );

    wire [31:0] ex_exec_result = (ex_wb_sel == `WB_CSR) ? ex_csr_rdata :
                                 ex_is_mdu              ? mdu_result   :
                                                          ex_alu_only_result;

    wire ex_branch_taken;
    rv32i_branch_unit u_branch_unit (
        .rs1_data     (ex_rs1_forwarded),
        .rs2_data     (ex_rs2_forwarded),
        .funct3       (ex_funct3),
        .is_branch    (ex_is_branch),
        .branch_taken (ex_branch_taken)
    );

    assign ex_pc_redirect     = trap_taken | mret_taken | ex_is_jal | ex_is_jalr | ex_branch_taken;
    assign ex_redirect_target = (trap_taken | mret_taken) ? trap_target_pc                :
                                ex_is_jalr                ? (ex_alu_only_result & ~32'd1) :
                                                            ex_alu_only_result;

    // Hazard Detection Unit
    rv32i_hazard_unit u_hazard_unit (
        .id_rs1_addr    (id_rs1),
        .id_rs2_addr    (id_rs2),
        .ex_mem_read    (ex_mem_read),
        .ex_rd_addr     (ex_rd_addr),
        .ex_pc_redirect (ex_pc_redirect),
        .mdu_busy       (mdu_busy),
        .pc_en          (pc_en),
        .if_id_en       (if_id_en),
        .id_ex_en       (id_ex_en),
        .if_id_flush    (if_id_flush),
        .id_ex_flush    (id_ex_flush),
        .ex_mem_flush   (ex_mem_flush)
    );

    // =========================================================================
    // PIPELINE REGISTER: EX / MEM
    // =========================================================================
    reg [31:0] mem_pc;
    reg [31:0] mem_pc_plus_4;
    reg [31:0] mem_alu_result;
    reg [31:0] mem_rs2_data;
    reg [2:0]  mem_funct3;
    reg        mem_mem_read;
    reg        mem_mem_write;
    reg [1:0]  mem_wb_sel;
    reg        mem_illegal_inst;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_pc           <= 32'h0000_0000;
            mem_pc_plus_4    <= 32'h0000_0000;
            mem_alu_result   <= 32'h0000_0000;
            mem_rs2_data     <= 32'h0000_0000;
            mem_rd_addr      <= 5'd0;
            mem_funct3       <= 3'b000;
            mem_reg_we       <= 1'b0;
            mem_mem_read     <= 1'b0;
            mem_mem_write    <= 1'b0;
            mem_wb_sel       <= `WB_ALU;
            mem_illegal_inst <= 1'b0;
        end else if (icg_en) begin
            if (ex_mem_flush || trap_taken || wfi_sleep_request_int) begin
                mem_pc           <= 32'h0000_0000;
                mem_pc_plus_4    <= 32'h0000_0000;
                mem_alu_result   <= 32'h0000_0000;
                mem_rs2_data     <= 32'h0000_0000;
                mem_rd_addr      <= 5'd0;
                mem_funct3       <= 3'b000;
                mem_reg_we       <= 1'b0;
                mem_mem_read     <= 1'b0;
                mem_mem_write    <= 1'b0;
                mem_wb_sel       <= `WB_ALU;
                mem_illegal_inst <= 1'b0;
            end else begin
                mem_pc           <= ex_pc;
                mem_pc_plus_4    <= ex_pc_plus_4;
                mem_alu_result   <= ex_exec_result;
                mem_rs2_data     <= ex_rs2_forwarded;
                mem_rd_addr      <= ex_rd_addr;
                mem_funct3       <= ex_funct3;
                mem_reg_we       <= ex_reg_we;
                mem_mem_read     <= ex_mem_read;
                mem_mem_write    <= ex_mem_write;
                mem_wb_sel       <= ex_wb_sel;
                mem_illegal_inst <= ex_illegal_inst;
            end
        end
    end

    // =========================================================================
    // STAGE 4: DATA MEMORY / MMIO ACCESS (MEM)
    // =========================================================================
    wire [31:0] mem_load_data;

    assign dmem_addr = mem_alu_result;
    assign dmem_re   = mem_mem_read & icg_en;

    assign mem_fwd_value = (mem_wb_sel == `WB_PC4) ? mem_pc_plus_4 : mem_alu_result;

    rv32i_lsu u_lsu (
        .addr_offset (mem_alu_result[1:0]),
        .funct3      (mem_funct3),
        .mem_write   (mem_mem_write & icg_en),
        .rs2_data    (mem_rs2_data),
        .dmem_rdata  (dmem_rdata),
        .dmem_wstrb  (dmem_wstrb),
        .dmem_wdata  (dmem_wdata),
        .load_data   (mem_load_data)
    );

    // =========================================================================
    // PIPELINE REGISTER: MEM / WB
    // =========================================================================
    reg [31:0] wb_pc;
    reg [31:0] wb_pc_plus_4;
    reg [31:0] wb_alu_result;
    reg [31:0] wb_load_data;
    reg [1:0]  wb_wb_sel;
    reg        wb_illegal_inst;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wb_pc           <= 32'h0000_0000;
            wb_pc_plus_4    <= 32'h0000_0000;
            wb_alu_result   <= 32'h0000_0000;
            wb_load_data    <= 32'h0000_0000;
            wb_rd_addr      <= 5'd0;
            wb_reg_we       <= 1'b0;
            wb_wb_sel       <= `WB_ALU;
            wb_illegal_inst <= 1'b0;
        end else if (icg_en) begin
            wb_pc           <= mem_pc;
            wb_pc_plus_4    <= mem_pc_plus_4;
            wb_alu_result   <= mem_alu_result;
            wb_load_data    <= mem_load_data;
            wb_rd_addr      <= mem_rd_addr;
            wb_reg_we       <= mem_reg_we;
            wb_wb_sel       <= mem_wb_sel;
            wb_illegal_inst <= mem_illegal_inst;
        end
    end

    // =========================================================================
    // STAGE 5: WRITEBACK (WB)
    // =========================================================================
    always @(*) begin
        case (wb_wb_sel)
            `WB_ALU: wb_rd_wdata = wb_alu_result;
            `WB_MEM: wb_rd_wdata = wb_load_data;
            `WB_PC4: wb_rd_wdata = wb_pc_plus_4;
            `WB_CSR: wb_rd_wdata = wb_alu_result;
            default: wb_rd_wdata = wb_alu_result;
        endcase
    end

    assign dbg_pc            = wb_pc;
    assign dbg_reg_we        = wb_reg_we & icg_en;
    assign dbg_rd_addr       = wb_rd_addr;
    assign dbg_rd_wdata      = wb_rd_wdata;
    assign illegal_inst      = wb_illegal_inst;
    assign wfi_sleep_request = wfi_sleep_request_int;
    assign global_mie        = global_mie_int;

endmodule
`default_nettype wire
