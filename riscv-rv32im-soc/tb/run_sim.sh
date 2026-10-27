#!/bin/bash
# =============================================================================
# Phase 5 RV32IM SoC Simulation Runner
# Uses Icarus Verilog + GTKWave
# =============================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIM_DIR="${PROJECT_DIR}/sim_build"
SRC_DIR="${PROJECT_DIR}/src"
TB_DIR="${PROJECT_DIR}/tb"
SW_DIR="${PROJECT_DIR}/sw"

echo "====================================================================="
echo "RV32IM Phase 5 SoC Simulation"
echo "Project: ${PROJECT_DIR}"
echo "====================================================================="

# Create build directory
mkdir -p "${SIM_DIR}"
cd "${SIM_DIR}"

# Compile with Icarus Verilog
echo "[1/3] Compiling Verilog sources..."
iverilog -g2012 \
    -I "${SRC_DIR}" \
    -o rv32im_phase5_soc_tb.vvp \
    "${TB_DIR}/rv32im_soc_tb.v" \
    "${SRC_DIR}"/*.v

echo "[2/3] Running simulation..."
vvp rv32im_phase5_soc_tb.vvp

echo "[3/3] Simulation complete!"
echo ""
echo "To view waveforms:"
echo "  gtkwave ${SIM_DIR}/rv32im_phase5_soc_tb.vcd"
echo ""
echo "VCD file: ${SIM_DIR}/rv32im_phase5_soc_tb.vcd"
