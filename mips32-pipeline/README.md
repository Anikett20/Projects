# 32-bit pipelined MIPS processor

Educational five-stage 32-bit MIPS-subset datapath with forwarding, load-use stall control, branch/jump flushing, register storage, and hardware instruction/data memories.

The active program is encoded in `src/instr_mem.v`; `examples/instr.txt` is the accompanying instruction reference. No external instruction file is needed to run the current RTL.

The supplied directed test checks six final register values and one data-memory value after its branch, jump, load/store, and forwarding sequence. This does not establish full MIPS ISA compliance or exhaustive hazard coverage.

## Run and inspect

From the repository root, with Python 3.10+ and Icarus Verilog installed:

```bash
python3 tools/run_checks.py --project mips32
```

The runner compiles only this project's sources, selects the intended testbench, rejects failure messages, checks the expected pass-message count, and saves a log and waveform under `sim_build/`. The new projects' checks use the supplied self-checking testbenches; they are directed tests, not an independent formal reference model.

For generic synthesis with Yosys, from this project directory:

```bash
yosys -s synth.ys
```

The generic synthesis script checks hierarchy and structure. It does not perform technology mapping, timing closure, or physical implementation. Current simulation and synthesis results are in [verification](../verification/).

## OpenLane and saved evidence

The root `config.json` and `config.tcl` reference the included `src/` files and target `MIPSpipeline` with a 20.0 ns clock. Use this project root as `DESIGN_DIR`; the old nested `designs/` layout is not required. These are OpenLane 1-style configs. With an appropriate OpenLane environment and SKY130 PDK installed, an example command from the OpenLane root is:

```bash
./flow.tcl -design /absolute/path/to/Projects/mips32-pipeline -tag new_run
```

The physical flow was **not rerun** for this upload. Exact historical tool/PDK revisions and resolved run configs were not supplied, so reproducing the saved layouts is not guaranteed.

Saved run `mips32_run1` reports `flow completed`, zero Magic/KLayout DRC violations, and zero LVS errors. However, nominal extracted WNS is **-4.22 ns**, the worst WNS in the three supplied extraction summaries is **-4.57 ns**, and there are **141 antenna pin / 118 antenna net violations**. These snapshots do not establish signoff readiness.

- [Selected report evidence](evidence/openlane/)
- [Full saved reports and layout archive](https://github.com/Anikett20/Projects/releases/download/project-artifacts-2026-10-27/mips32-pipeline-physical-artifacts.zip)
- [Release and checksums](https://github.com/Anikett20/Projects/releases/tag/project-artifacts-2026-10-27)
- [Upload completeness audit](../verification/UPLOAD_AUDIT.md)
