# Projects

Selected academic projects by **Aniket Kulkarni**, covering Verilog RTL, simulation, synthesis, and physical-design exploration.

| Project | What is included | Current evidence |
| --- | --- | --- |
| [RV32IM microcontroller SoC](riscv-rv32im-soc/) | Five-stage processor, multiply/divide unit, machine CSRs, UART, GPIO, timer, SPI, and WFI sleep control | Directed firmware simulation; saved SKY130/OpenLane reports with remaining timing and antenna violations |
| [4-bit registered ALU](alu-4bit/) | Eight arithmetic/logic operations, registered outputs, carry and zero flags | Directed simulation; Design Compiler, ICC II, and PrimeTime report snapshots |
| [8-bit ALU and register datapath](alu-8bit-datapath/) | ALU, eight-register file, instruction decoder, and integration examples | RTL simulation; instructions are supplied externally |

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
```

The runner compiles each design separately, checks the observable results of the included directed testbenches, and writes logs to each project's `sim_build/` directory. A machine-readable summary is saved in [verification/results.json](verification/results.json). GitHub Actions runs the same checks.

These checks cover the supplied examples. They do not establish full RISC-V ISA compliance, exhaustive verification, timing closure, or silicon readiness.

## Repository layout

```text
alu-4bit/            Registered ALU, testbench, constraints, flow references, reports
alu-8bit-datapath/   ALU, register file, control unit, and integration testbenches
riscv-rv32im-soc/    Latest microcontroller RTL, firmware, OpenLane configs, reports
tools/              Portable simulation/check runner
verification/       Recorded validation summary
```

The upload uses the latest RISC-V microcontroller source snapshot rather than duplicating all development phases. Compiled simulators, waveforms, tool databases, technology libraries, and the large GDS file are excluded. Proprietary EDA tools and their technology libraries must be obtained separately.

See [PACKAGING.md](PACKAGING.md) for source provenance and the small testbench corrections made while preparing this repository.
