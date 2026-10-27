# =============================================================================
# OpenLane 1.1.1 Tcl Configuration for Phase 5 RV32IM + Zicsr SoC (`rv32im_soc`)
# Hardens the Complete Microcontroller SoC (Core + MDU + CSR + UART + GPIO +
# Timer + SPI Master + WFI Sleep Controller)
# =============================================================================
set ::env(DESIGN_NAME) "rv32im_soc"

set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.v]
set ::env(VERILOG_INCLUDE_DIRS) [list $::env(DESIGN_DIR)/src]

set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_NET) "clk"
set ::env(CLOCK_PERIOD) "20.0"

# 1000x1000 um die for full Phase 5 SoC (~16k cells) with ample routing headroom
set ::env(FP_SIZING) "absolute"
set ::env(DIE_AREA) "0 0 1000 1000"
set ::env(FP_CORE_UTIL) 30
set ::env(PL_TARGET_DENSITY) 0.34

# Synthesis & Slew/Fanout Optimization (fixes Typical corner slew/fanout warnings)
set ::env(SYNTH_STRATEGY) "AREA 0"
set ::env(MAX_FANOUT_CONSTRAINT) 4
set ::env(MAX_TRANSITION_CONSTRAINT) 0.75
set ::env(PL_RESIZER_MAX_SLEW_MARGIN) 25
set ::env(PL_RESIZER_MAX_CAP_MARGIN) 25
set ::env(GRT_RESIZER_MAX_SLEW_MARGIN) 25
set ::env(GRT_RESIZER_MAX_CAP_MARGIN) 25
set ::env(RT_MAX_LAYER) "met5"

# Keep GRT_REPAIR_ANTENNAS=0 so OpenROAD Step 22 never crashes with GRT-0232
set ::env(GRT_ADJUSTMENT) 0.2
set ::env(DIODE_INSERTION_STRATEGY) 0
set ::env(GRT_REPAIR_ANTENNAS) 0
set ::env(RUN_HEURISTIC_DIODE_INSERTION) 0
