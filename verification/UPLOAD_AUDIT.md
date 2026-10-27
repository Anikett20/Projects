# Upload completeness audit - 27 October 2026

Four projects from `D:/Projects` were prepared for `Anikett20/Projects`. The three existing repository projects were retained. Original local project folders were not modified.

## Included and verified

- 37 RTL source files, five supplied testbenches, reference program files, project configs, simulation entry points, generic synthesis scripts, and project READMEs.
- Every `VERILOG_FILES` entry resolves to an included source. Icarus elaboration resolves the testbench/module dependencies.
- All seven repository projects pass their supplied simulation checks using Icarus Verilog version 12.0 (stable) (). The four added projects emit 9, 7, 22, and 16 pass markers respectively. See [results.json](results.json) and [simulation logs](simulations/).
- All four added top-level designs pass Yosys generic synthesis and `check -assert`. Memory-to-register lowering warnings are recorded in [synthesis-results.json](synthesis-results.json); this was not a physical flow rerun.
- Unmodified source-byte SHA-256 values are recorded in [source-manifest.json](source-manifest.json).
- All 459 supplied files under the four `reports/` and `gds/` trees are preserved in four [release archives](https://github.com/Anikett20/Projects/releases/tag/project-artifacts-2026-10-27), including the GDS layouts. Each archive has per-file SHA-256 metadata and the supplied source configs. ZIP CRC integrity checks passed; release checksums are in [artifact-checksums.txt](artifact-checksums.txt).

## Historical physical-design results

All four metrics files say `flow completed` and report zero Magic/KLayout DRC violations and zero LVS errors. The table uses extracted timing and antenna counts, which must not be hidden by the earlier-stage `wns = 0` column.

| Project | Saved run | Nominal extracted WNS (ns) | Worst WNS in supplied extraction summaries (ns) | Antenna pins / nets |
| --- | --- | ---: | ---: | ---: |
| [16-bit MIPS-style single-cycle processor](../mips16/) | mips16_run1 | -1.26 | -1.56 | 16 / 16 |
| [32-bit pipelined MIPS processor](../mips32-pipeline/) | mips32_run1 | -4.22 | -4.57 | 141 / 118 |
| [32-bit synchronous FIFO memory](../fifo-memory/) | fifo32_run1 | 0.0 | 0 | 5 / 4 |
| [4x4 fixed-point matrix multiplication](../fixed-point-matrix-multiplication/) | fpmm_run1 | -0.86 | -1.32 | 43 / 40 |

Three projects have negative extracted setup slack; all four have antenna violations. The supplied configs disable antenna repair. The uploaded designs are educational work with historical implementation evidence, not signed-off silicon.

## Packaging corrections

- Published one canonical `src/` tree per project instead of duplicate root copies or a second monolithic definition. The FIFO's separate `fifo_memo.v` is included because its testbench instantiates it alongside `fifo_memory`.
- Replaced fragile project runners with wrappers around the repository check command. The runner rejects `[SELF-CHECK FAIL]` even if the simulator exits with status zero.
- Changed only the 16-bit MIPS testbench's waveform destination from `output/waveform.vcd` to `mips16_waveform.vcd`, relative to the simulation output directory. Design RTL was not modified.
- Rewrote the 16-bit MIPS README to match its actual custom 4-bit opcode, 3-bit register fields, 6-bit immediate, and current memory sizes. The original README had incompatible encoding widths and larger memory claims.
- Used the root OpenLane configs. The omitted nested 16-bit `designs/mips16` configs referred to an absent `src/` directory; old runner/Makefile paths were not portable. Generic synthesis no longer assumes `/usr/share/yosys/cells.lib` or a graphical viewer.

## What stays local, and what is still missing

Compiled simulators, generated VCDs, backup files, cloud-sync temporary folders, duplicate sources, and `apply_*_fixes.sh` workstation rewrite scripts were excluded. Existing waveform screenshots are included where supplied. Full reports and physical outputs are release downloads instead of hundreds of megabytes in Git history.

The supplied material is sufficient to compile and run the included directed RTL examples. It is not a complete reproducible physical-design environment: exact historical OpenLane/tool/PDK locks, resolved run configuration, complete run logs, and a source-to-layout provenance chain are unavailable. The 16-bit MIPS, 32-bit MIPS, and matrix folders contain GDS but no final gate-level netlist/SDC/DEF bundle; the FIFO archive contains these additional outputs. Obtain those original run products for gate-level or physical reproduction of the other three.

No standalone license file or complete third-party attribution record was supplied for these four folders. No new license grant was invented. The original 16-bit README's MIT sentence alone was not copied as a repository-wide license.

Verification remains limited to the supplied examples. In particular, the FIFO simultaneous-activity suite lacks a full data scoreboard and uses some edge-coincident stimulus; the matrix example tests one fixed pair of matrices; neither processor has an exhaustive ISA/compliance suite here.
