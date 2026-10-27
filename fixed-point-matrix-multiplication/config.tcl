# =============================================================================
# OpenLane 1.1.1 Tcl Configuration for 4x4 Fixed-Point Matrix Multiplier
# Top Module : matrix_multiplication
# Target PDK : SkyWater 130nm (sky130_fd_sc_hd)
# =============================================================================
set ::env(DESIGN_NAME) "matrix_multiplication"

set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.v]

set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_NET) "clk"
set ::env(CLOCK_PERIOD) "20.0"

# 750x750 um die for parallel 4x4 Q7.8 matrix multiplier array (~7.5k cells)
set ::env(FP_SIZING) "absolute"
set ::env(DIE_AREA) "0 0 750 750"
set ::env(FP_CORE_UTIL) 35
set ::env(PL_TARGET_DENSITY) 0.40

# Synthesis & Slew/Fanout Optimization (prevents slew/fanout violations)
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
