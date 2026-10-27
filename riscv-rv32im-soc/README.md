# RV32IM microcontroller SoC

The latest Phase 5 snapshot of an educational five-stage RISC-V microcontroller implemented in Verilog.

## Design overview

- RV32I processor pipeline with forwarding and hazard control.
- Multiply/divide unit for RV32M instructions.
- Machine-mode CSR, timer interrupt, trap, and return logic.
- Memory-mapped UART, 32-bit GPIO, timer, and SPI controller.
- WFI sleep controller that pauses core progress and wakes on an interrupt.
- External Harvard instruction/data memory interfaces; the testbench supplies memory.

The UART and SPI are custom RTL peripherals. Their compatibility and operating modes should be assessed from their implementations and further verification. The included firmware exercises a directed integration scenario, not a full ISA or peripheral compliance suite.

## Simulation

From the repository root:

```bash
python3 tools/run_checks.py --project riscv
```

The original standalone runner is also available:

```bash
bash riscv-rv32im-soc/tb/run_sim.sh
```

The Python command additionally checks every printed expected memory/GPIO value, WFI entry, timer wake, SPI activity, and completion. The supplied firmware completed at cycle 273 during preparation of this repository.

| Check | Expected value |
| --- | --- |
| `1234 * 5678` | `0x006ae9bc` |
| `7006652 / 1234` | `0x0000162e` |
| `7006652 % 1000` | `0x0000028c` |
| Timer interrupt cause | `0x80000007` |
| SPI loopback byte | `0x0000005a` |
| GPIO output | `0x006ae9bc` |
| Firmware completion flag | `0xcafebabe` |

The short firmware initializes part of a larger instruction-memory array, so Icarus emits a `$readmemh` short-file warning. The testbench pre-fills the array with NOPs before loading the firmware.

## OpenLane configuration and saved reports

[config.json](config.json) and [config.tcl](config.tcl) target `rv32im_soc`, a 20 ns input clock, and a 1000 x 1000 micrometre die. A compatible OpenLane/SKY130 installation is required for a new physical-design run.

Saved [phase5_run1 reports](evidence/openlane/) show:

| Observation | Source |
| --- | --- |
| Flow status `flow completed`; 18,105 synthesis cells | [metrics.csv](evidence/openlane/metrics.csv) |
| Zero reported Magic DRC errors and LVS mismatches | [manufacturability.rpt](evidence/openlane/manufacturability.rpt), [LVS report](evidence/openlane/signoff/41-rv32im_soc.lvs.rpt) |
| 507 antenna pin violations across 336 nets | [manufacturability.rpt](evidence/openlane/manufacturability.rpt) |
| RCX min: setup WNS -0.83 ns, hold worst slack +0.11 ns | [min summary](evidence/openlane/signoff/29-sta-rcx_min/multi_corner_sta.summary.rpt) |
| RCX nominal: setup WNS -1.14 ns, hold worst slack +0.11 ns | [nominal summary](evidence/openlane/signoff/33-sta-rcx_nom/multi_corner_sta.summary.rpt) |
| RCX max: setup WNS -1.42 ns, hold worst slack +0.12 ns | [max summary](evidence/openlane/signoff/31-sta-rcx_max/multi_corner_sta.summary.rpt) |

These snapshots show completed flow stages with open setup timing and antenna violations. They do not establish signoff readiness or a verified 50 MHz implementation. Metrics at different flow stages and RC extraction settings are retained separately; they should not be combined into a single timing result.
