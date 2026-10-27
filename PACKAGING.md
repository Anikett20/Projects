# Source and packaging notes

This repository was prepared from three academic project folders on 27 October 2026:

| Published directory | Original project |
| --- | --- |
| `riscv-rv32im-soc/` | `RISC V/RISC V microcontroller soc/`, latest Phase 5 sources |
| `alu-4bit/` | `4BitALU/`, with saved reports from its `ALU_Project/` directory |
| `alu-8bit-datapath/` | `Soc 8 BIT ALU/` |

Design RTL and saved report contents are preserved, with text line endings normalized to LF. Source files were copied into the published layout; the original project sources were retained.

Two testbench corrections are included:

1. In `alu-8bit-datapath/tb/soc_top_tb.v`, the two LOAD instructions now use `{opcode[3:0], rd[2:0], 1'b0, immediate[7:0]}`. The original concatenations were 18 bits wide and lost their opcode bits when assigned to the 16-bit program memory. The corrected encodings are `0x820f` and `0x8405`.
2. In `alu-4bit/tb/tb_alu_4bit.v`, reset is released at 12 ns instead of 15 ns. This separates testbench stimulus from the rising clock edge and avoids a simulation race.

The Python runner checks results from the supplied testbenches rather than accepting a success message or simulator exit code alone. The original 8-bit `soc_core_tb.v` remains as an example; its force/release of individual memory words is simulator-dependent and is not part of the portable check command.

RISC-V report snapshots belong to `phase5_run1`. The repository does not claim that those historical physical-design results were regenerated from this upload. The 4-bit ALU reports come from separate saved tool stages and must not be treated as one completed, signed-off implementation.
