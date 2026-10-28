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

## Additional MIPS, FIFO, and matrix projects

Four more project folders were packaged on 27 October 2026:

| Published directory | Original folder under `D:/Projects` |
| --- | --- |
| `mips16/` | `16-bit MIPS/` |
| `mips32-pipeline/` | `32-bit MIPS/` |
| `fifo-memory/` | `FIFO Memory/` |
| `fixed-point-matrix-multiplication/` | `Fixed point matrix multiplication/` |

See [the upload audit](verification/UPLOAD_AUDIT.md) for source preservation, the waveform-path correction, runnable entry points, physical-artifact downloads, and remaining gaps. No design RTL was changed for these four uploads. The FIFO's separate structural implementation was added to its published source directory to satisfy the supplied testbench.

## Synthesis images added on 28 October 2026

Added 16 original synthesis screenshots and schematic exports from the four project folders. Eleven PNGs are stored under each project's `docs/synthesis/`; five large PNGs are available in the [synthesis-image release](https://github.com/Anikett20/Projects/releases/tag/synthesis-images-2026-10-28). Project READMEs show a screenshot and link every schematic. No images were resized, recompressed, or otherwise changed. Dimensions, file sizes, source filenames, storage locations, and SHA-256 values are recorded in [verification/synthesis-images.json](verification/synthesis-images.json). The four separate `LinkedIn_*` summary charts are outside this synthesis-image update.
