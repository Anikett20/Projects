# 4x4 fixed-point matrix multiplication

A fixed 4x4 matrix multiplier using 16-bit sign-magnitude Q7.8 values: bit 15 is the sign, bits 14:8 hold the integer magnitude, and bits 7:0 hold the fraction. This representation is not two's complement.

`Matrix_A.v` and `ROM.v` contain the input matrices. The datapath forms the 16 dot products with 64 multipliers and 48 adders, stores the results, and streams them on `data_out`. The supplied testbench compares all 16 elements against its expected matrix. No external ROM/IP files are required. Overflow, saturation, and arbitrary-matrix coverage are not established by this one directed example.

## Synthesis images

[![Fixed-point matrix multiplication synthesis screenshot](docs/synthesis/fpmm-synthesis.png)](docs/synthesis/)

[View all 4 synthesis screenshots and schematics](docs/synthesis/), including full-resolution gate diagrams.

## Run and inspect

From the repository root, with Python 3.10+ and Icarus Verilog installed:

```bash
python3 tools/run_checks.py --project fpmm
```

The runner compiles only this project's sources, selects the intended testbench, rejects failure messages, checks the expected pass-message count, and saves a log and waveform under `sim_build/`. The new projects' checks use the supplied self-checking testbenches; they are directed tests, not an independent formal reference model.

For generic synthesis with Yosys, from this project directory:

```bash
yosys -s synth.ys
```

The generic synthesis script checks hierarchy and structure. It does not perform technology mapping, timing closure, or physical implementation. Current simulation and synthesis results are in [verification](../verification/).

## OpenLane and saved evidence

The root `config.json` and `config.tcl` reference the included `src/` files and target `matrix_multiplication` with a 20.0 ns clock. Use this project root as `DESIGN_DIR`; the old nested `designs/` layout is not required. These are OpenLane 1-style configs. With an appropriate OpenLane environment and SKY130 PDK installed, an example command from the OpenLane root is:

```bash
./flow.tcl -design /absolute/path/to/Projects/fixed-point-matrix-multiplication -tag new_run
```

The physical flow was **not rerun** for this upload. Exact historical tool/PDK revisions and resolved run configs were not supplied, so reproducing the saved layouts is not guaranteed.

Saved run `fpmm_run1` reports `flow completed`, zero Magic/KLayout DRC violations, and zero LVS errors. However, nominal extracted WNS is **-0.86 ns**, the worst WNS in the three supplied extraction summaries is **-1.32 ns**, and there are **43 antenna pin / 40 antenna net violations**. These snapshots do not establish signoff readiness.

- [Selected report evidence](evidence/openlane/)
- [Full saved reports and layout archive](https://github.com/Anikett20/Projects/releases/download/project-artifacts-2026-10-27/fixed-point-matrix-multiplication-physical-artifacts.zip)
- [Release and checksums](https://github.com/Anikett20/Projects/releases/tag/project-artifacts-2026-10-27)
- [Upload completeness audit](../verification/UPLOAD_AUDIT.md)
