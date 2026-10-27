# =============================================================================
# OpenLane 1.1.1 Tcl Configuration for 32-Bit 5-Stage Pipelined MIPS
# Top Module : MIPSpipeline
# Target PDK : SkyWater 130nm (sky130_fd_sc_hd)
# =============================================================================
set ::env(DESIGN_NAME) "MIPSpipeline"

set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.v]

set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_NET) "clk"
set ::env(CLOCK_PERIOD) "20.0"

# 750x750 um die for 32-bit 5-stage MIPS core + 32x32 RegFile + 16x32 DMEM
set ::env(FP_SIZING) "absolute"
set ::env(DIE_AREA) "0 0 750 750"
set ::env(FP_CORE_UTIL) 35
set ::env(PL_TARGET_DENSITY) 0.40

set ::env(SYNTH_STRATEGY) "AREA 0"
set ::env(MAX_FANOUT_CONSTRAINT) 6
set ::env(MAX_TRANSITION_CONSTRAINT) 0.75
set ::env(PL_RESIZER_MAX_SLEW_MARGIN) 25
set ::env(PL_RESIZER_MAX_CAP_MARGIN) 25
set ::env(GRT_RESIZER_MAX_SLEW_MARGIN) 25
set ::env(GRT_RESIZER_MAX_CAP_MARGIN) 25
set ::env(RT_MAX_LAYER) "met5"

set ::env(GRT_ADJUSTMENT) 0.2
set ::env(DIODE_INSERTION_STRATEGY) 0
set ::env(GRT_REPAIR_ANTENNAS) 0
set ::env(RUN_HEURISTIC_DIODE_INSERTION) 0
