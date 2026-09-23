#!/usr/bin/env bash
set -euo pipefail
for f in openfpga/arch/vpr_arch_2x2.xml openfpga/arch/vsd_openfpga_arch_scl1d.xml; do [[ -f "$f" ]] || { echo "missing $f"; exit 2; }; done
: "${OPENFPGA_PATH:?source openfpga.sh first}"
export VPR_ARCH_FILE="$PWD/openfpga/arch/vpr_arch_2x2.xml"
export OPENFPGA_ARCH_FILE="$PWD/openfpga/arch/vsd_openfpga_arch_scl1d.xml"
export VPR_TESTBENCH_BLIF="$PWD/openfpga/benchmarks/and2.blif"
export VPR_TESTBENCH_VERILOG="$PWD/openfpga/benchmarks/and2.v"
export ACTIVITY_FILE="$PWD/openfpga/benchmarks/and2.act"
export OPENFPGA_VPR_ROUTE_CHAN_WIDTH="20"
export OPENFPGA_OUTPUT_DIR="$PWD/results/2x2"
export OPENFPGA_SIM_SETTING_FILE="${OPENFPGA_SIM_SETTING_FILE:-$OPENFPGA_PATH/openfpga_flow/openfpga_simulation_setting.xml}"
mkdir -p "$OPENFPGA_OUTPUT_DIR"
openfpga_shell -f openfpga/scripts/openfpga_fab_scl1d.tcl
