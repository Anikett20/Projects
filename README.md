# Projects

Selected academic projects by **Aniket Kulkarni**, covering Verilog RTL, simulation, synthesis, and physical-design exploration.

| Project | What is included | Current evidence |
| --- | --- | --- |
| [RV32IM microcontroller SoC](riscv-rv32im-soc/) | Five-stage processor, multiply/divide unit, machine CSRs, UART, GPIO, timer, SPI, and WFI sleep control | Directed firmware simulation; saved SKY130/OpenLane reports with remaining timing and antenna violations |
| [4-bit registered ALU](alu-4bit/) | Eight arithmetic/logic operations, registered outputs, carry and zero flags | Directed simulation; Design Compiler, ICC II, and PrimeTime report snapshots |
| [8-bit ALU and register datapath](alu-8bit-datapath/) | ALU, eight-register file, instruction decoder, and integration examples | RTL simulation; instructions are supplied externally |
| [16-bit MIPS-style processor](mips16/) | Custom single-cycle ISA, RTL, ROM program, testbenches, OpenLane configs | Directed simulation and generic synthesis pass; saved reports have timing and antenna violations |
| [32-bit pipelined MIPS](mips32-pipeline/) | Five-stage datapath, forwarding/stalls, testbench, OpenLane configs | Directed simulation and generic synthesis pass; saved reports have timing and antenna violations |
| [32-bit FIFO memory](fifo-memory/) | Parameterized and structural synchronous FIFOs, eight test suites | Directed simulation and generic synthesis pass; saved reports have antenna violations |
| [4x4 fixed-point matrix multiplier](fixed-point-matrix-multiplication/) | Sign-magnitude Q7.8 datapath, ROM inputs, 16-result testbench | Directed simulation and generic synthesis pass; saved reports have timing and antenna violations |

Each project has its own README, source files, and testbenches. Physical results are described with their limitations alongside the original report excerpts.

## Run the simulations

Requires **Python 3.10+** and **Icarus Verilog** (`iverilog` and `vvp`) on your PATH. On Windows, the commands can be run inside WSL.

```bash
python3 tools/run_checks.py
```

To check one project:

```bash
python3 tools/run_checks.py --project riscv
python3 tools/run_checks.py --project alu4
python3 tools/run_checks.py --project alu8
python3 tools/run_checks.py --project mips16
python3 tools/run_checks.py --project mips32
python3 tools/run_checks.py --project fifo
python3 tools/run_checks.py --project fpmm
```

The runner compiles each design separately, checks the observable results of the included directed testbenches, and writes logs to each project's `sim_build/` directory. A machine-readable summary is saved in [verification/results.json](verification/results.json). GitHub Actions runs the same checks.

These checks cover the supplied examples. They do not establish full RISC-V ISA compliance, exhaustive verification, timing closure, or silicon readiness.

## Repository layout

```text
alu-4bit/            Registered ALU, testbench, constraints, flow references, reports
alu-8bit-datapath/   ALU, register file, control unit, and integration testbenches
riscv-rv32im-soc/    Latest microcontroller RTL, firmware, OpenLane configs, reports
mips16/             Custom 16-bit single-cycle processor
mips32-pipeline/    32-bit five-stage MIPS-subset processor
fifo-memory/        Two 16x32 synchronous FIFO implementations
fixed-point-matrix-multiplication/  4x4 sign-magnitude Q7.8 matrix multiplier
tools/              Portable simulation/check runner
verification/       Recorded validation summary
```

The upload uses the latest RISC-V microcontroller source snapshot rather than duplicating all development phases. Compiled simulators, waveforms, tool databases, technology libraries, and the RISC-V GDS file are excluded from the source tree. Proprietary EDA tools and their technology libraries must be obtained separately.

See [PACKAGING.md](PACKAGING.md) for source provenance and the small testbench corrections made while preparing this repository.

## Reports and layout downloads

The four MIPS/FIFO/matrix projects include selected reports in Git and complete supplied report/layout bundles in the [physical-artifact release](https://github.com/Anikett20/Projects/releases/tag/project-artifacts-2026-10-27). The release includes GDS files, per-file manifests, and SHA-256 checksums. See the [upload audit](verification/UPLOAD_AUDIT.md) for exactly what is included, missing physical-reproduction inputs, and timing/antenna limitations.

## Synthesis image galleries

- [16-bit MIPS](mips16/docs/synthesis/) - 4 images
- [32-bit pipelined MIPS](mips32-pipeline/docs/synthesis/) - 5 images
- [FIFO memory](fifo-memory/docs/synthesis/) - 3 images
- [Fixed-point matrix multiplication](fixed-point-matrix-multiplication/docs/synthesis/) - 4 images
