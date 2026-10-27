// =============================================================================
// File        : rv32i_defs.vh
// Project     : RV32IM + Zicsr 5-Stage Pipelined SoC (OpenLane SKY130 Target)
// Description : Central ISA Opcodes, ALU/MDU/CSR Operations, and SoC Memory Map
// =============================================================================
`ifndef RV32I_DEFS_VH
`define RV32I_DEFS_VH

// RV32I / RV32M / Zicsr Base Opcodes (inst[6:0])
`define OPCODE_LUI      7'b0110111
`define OPCODE_AUIPC    7'b0010111
`define OPCODE_JAL      7'b1101111
`define OPCODE_JALR     7'b1100111
`define OPCODE_BRANCH   7'b1100011
`define OPCODE_LOAD     7'b0000011
`define OPCODE_STORE    7'b0100011
`define OPCODE_OP_IMM   7'b0010011
`define OPCODE_OP       7'b0110011
`define OPCODE_MISC_MEM 7'b0001111
`define OPCODE_SYSTEM   7'b1110011

// Canonical NOP Instruction (ADDI x0, x0, 0)
`define INST_NOP        32'h0000_0013

// ALU Operation Encodings (4-bit)
`define ALU_ADD    4'b0000
`define ALU_SUB    4'b0001
`define ALU_SLL    4'b0010
`define ALU_SLT    4'b0011
`define ALU_SLTU   4'b0100
`define ALU_XOR    4'b0101
`define ALU_SRL    4'b0110
`define ALU_SRA    4'b0111
`define ALU_OR     4'b1000
`define ALU_AND    4'b1001
`define ALU_PASS_B 4'b1010

// RV32M Multiply/Divide funct3 Encodings
`define MDU_MUL    3'b000
`define MDU_MULH   3'b001
`define MDU_MULHSU 3'b010
`define MDU_MULHU  3'b011
`define MDU_DIV    3'b100
`define MDU_DIVU   3'b101
`define MDU_REM    3'b110
`define MDU_REMU   3'b111

// Zicsr funct3 Encodings
`define CSR_RW     3'b001
`define CSR_RS     3'b010
`define CSR_RC     3'b011
`define CSR_RWI    3'b101
`define CSR_RSI    3'b110
`define CSR_RCI    3'b111

// Machine-Mode CSR Addresses (12-bit)
`define CSR_MSTATUS  12'h300
`define CSR_MIE      12'h304
`define CSR_MTVEC    12'h305
`define CSR_MSCRATCH 12'h340
`define CSR_MEPC     12'h341
`define CSR_MCAUSE   12'h342
`define CSR_MIP      12'h344
`define CSR_MCYCLE   12'hB00
`define CSR_MINSTRET 12'hB02

// Immediate Format Select (3-bit)
`define IMM_I 3'b000
`define IMM_S 3'b001
`define IMM_B 3'b010
`define IMM_U 3'b011
`define IMM_J 3'b100

// Writeback Source Select (2-bit)
`define WB_ALU  2'b00
`define WB_MEM  2'b01
`define WB_PC4  2'b10
`define WB_CSR  2'b11

// Forwarding Mux Select (2-bit)
`define FWD_NONE 2'b00
`define FWD_WB   2'b01
`define FWD_MEM  2'b10

// Memory-Mapped I/O Base Address Prefix (0x1000_xxxx)
`define MMIO_BASE_PREFIX 16'h1000
`define MMIO_UART_TXDATA 8'h00
`define MMIO_UART_STATUS 8'h04
`define MMIO_UART_BAUD   8'h08
`define MMIO_GPIO_OUT    8'h10
`define MMIO_GPIO_IN     8'h14
`define MMIO_TIMER_CNT   8'h20
`define MMIO_TIMER_CMP   8'h24
`define MMIO_SPI_BASE    8'h30  // SPI Master at 0x1000_0030
`define MMIO_SPI_CTRL    8'h30
`define MMIO_SPI_CLKDIV  8'h34
`define MMIO_SPI_TXDATA  8'h38
`define MMIO_SPI_STATUS  8'h3C
`define MMIO_SPI_CS      8'h40
`define MMIO_SPI_IRQ_EN  8'h44

// WFI Instruction: SYSTEM opcode (1110011), funct3=000, rs2=0, rd=0, funct12=0
`define INST_WFI         32'h0000_1073

`endif // RV32I_DEFS_VH
