# 8-bit ALU and register datapath

An educational Verilog datapath integrating a combinational ALU, an 8 x 8-bit register file, and a decoder for externally supplied 16-bit instructions. The original module names `soc_core` and `soc_top` are retained.

The top-level design has no instruction fetch engine, internal program counter, or program memory. The integration testbench supplies each instruction.

## Modules

| Module | Role |
| --- | --- |
| `alu` | ADD, SUB, AND, OR, XOR, NOT, SHL, SHR; zero and carry/borrow/shift flags |
| `reg_file` | Two asynchronous reads and one synchronous write; R0 is hardwired to zero |
| `control_unit` | Decodes arithmetic, logic, LOAD, MOV, NOP, and HLT |
| `soc_core` | ALU and register file with external control signals |
| `soc_top` | Decoder, immediate writeback mux, register file, and ALU |

## Instruction encoding

Arithmetic/logic instructions use `{opcode[3:0], rd[2:0], ra[2:0], rb[2:0], 3'b000}`. Opcodes `0x0` through `0x7` map to the ALU operations listed above.

| Opcode | Meaning |
| --- | --- |
| `0x8` | LOAD: `{4'h8, rd[2:0], 1'b0, immediate[7:0]}` |
| `0x9` | MOV: `rd = ra` |
| `0xA` | NOP: disable register write |
| `0xB` | HLT: assert halt and disable register write for the current instruction |

HLT is combinational rather than a latched processor state; replacing the HLT instruction releases it. The decoder's clock/reset and flag inputs do not currently implement sequential control or conditional branches. Flags describe the current ALU output, which can differ from immediate writeback data during LOAD.

## Simulation

From the repository root:

```bash
python3 tools/run_checks.py --project alu8
```

The runner checks 11 standalone ALU cases and the eight-instruction LOAD/ADD/SUB/AND/SHL/XOR/HLT integration example. Additional register-file, decoder, and `soc_core` demonstration testbenches are retained under `tb/`; they are not all self-checking or included in the portable runner.

The two LOAD encodings in the integration testbench were corrected during packaging; see [PACKAGING.md](../PACKAGING.md). This folder contains RTL and simulation evidence. Physical implementation results for this exact integrated design are not included.
