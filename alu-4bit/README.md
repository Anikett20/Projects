# 4-bit registered ALU

A Verilog ALU with two 4-bit operands, a 3-bit opcode, registered result/carry/zero outputs, and an asynchronous active-high reset.

| Opcode | Operation |
| --- | --- |
| `000` | ADD |
| `001` | SUB |
| `010` | AND |
| `011` | OR |
| `100` | XOR |
| `101` | NOT A |
| `110` | Logical shift left A by one |
| `111` | Logical shift right A by one |

Addition and subtraction use a 5-bit temporary result. Shift results are truncated to four bits and their carry output is cleared. Reset clears all outputs, including the zero flag; during normal operation the zero flag reflects the registered result.

## Simulation

From the repository root:

```bash
python3 tools/run_checks.py --project alu4
```

The supplied testbench contains nine directed scenarios covering seven opcodes, including addition overflow, subtraction, logic, a left shift, and a zero result. The runner checks the recorded VCD values at settled falling clock edges. SHR is implemented in RTL but is not exercised by this testbench.

## Synthesis and physical-design evidence

Saved reports are included under [evidence/](evidence/). They are historical snapshots, not a new tool run.

| Artifact | Observation |
| --- | --- |
| [Design Compiler area](evidence/DC/reports/area_report.txt) | SAED32 RVT mapping; 213 cells; combinational area 375.116557; total cell area 417.812750, in library area units |
| [Design Compiler timing](evidence/DC/reports/timing_report.txt) | The reported path has setup slack of -0.06 ns against a 1.2 ns clock |
| [ICC II QoR](evidence/ICCII/icc2_qor_report.txt) | Reports 213 leaf cells, but warns that valid parasitics are missing and zero interconnect delay is used |
| [ICC II verification](evidence/ICCII/icc2_drc_report.txt) | Zero open nets and 178 DRCs; antenna rules were not defined |
| [PrimeTime setup](evidence/PT/setup_timing.txt) | Reports `No constrained paths`; it does not establish timing closure |

The [SDC snapshot](constraints/alu_4bit.sdc) and [flow reference scripts](flow/) are included for context. The Design Compiler reference expects RTL in its working directory and a configured target library. The ICC II reference expects the original netlist/PDK layout and performs initial floorplanning/placement. Update these paths and provide licensed tools and SAED32 libraries before using them in another environment. The PDK, vendor setup files, and technology cell models are not bundled.
