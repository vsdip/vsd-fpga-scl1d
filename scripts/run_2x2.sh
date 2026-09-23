#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$(cd -- "$script_dir/.." && pwd)"

for f in \
  openfpga/arch/vpr_arch_2x2.xml \
  openfpga/arch/vsd_openfpga_arch_scl1d.xml
do
  [[ -f "$f" ]] || {
    echo "missing $f"
    exit 2
  }
done

openfpga_bin="$(bash scripts/openfpga_tool.sh --print-path)"

if [[ -z "${OPENFPGA_PATH:-}" ]]; then
  case "$openfpga_bin" in
    */openfpga/openfpga)
      export OPENFPGA_PATH="${openfpga_bin%/openfpga/openfpga}"
      ;;
    */openfpga)
      export OPENFPGA_PATH="${openfpga_bin%/openfpga}"
      ;;
    *)
      echo "Cannot derive OPENFPGA_PATH from $openfpga_bin"
      exit 2
      ;;
  esac
fi

export VPR_ARCH_FILE="$PWD/openfpga/arch/vpr_arch_2x2.xml"
export OPENFPGA_ARCH_FILE="$PWD/openfpga/arch/vsd_openfpga_arch_scl1d.xml"
export VPR_TESTBENCH_BLIF="$PWD/openfpga/benchmarks/and2.blif"
export VPR_TESTBENCH_VERILOG="$PWD/openfpga/benchmarks/and2.v"
export ACTIVITY_FILE="$PWD/openfpga/benchmarks/and2.act"
export OPENFPGA_VPR_ROUTE_CHAN_WIDTH="20"
export OPENFPGA_OUTPUT_DIR="$PWD/results/2x2"

if [[ -z "${OPENFPGA_SIM_SETTING_FILE:-}" ]]; then
  if [[ -f "$PWD/openfpga/arch/scl1d_simulation_setting.xml" ]]; then
    export OPENFPGA_SIM_SETTING_FILE="$PWD/openfpga/arch/scl1d_simulation_setting.xml"
  else
    export OPENFPGA_SIM_SETTING_FILE="$OPENFPGA_PATH/openfpga_flow/openfpga_simulation_setting.xml"
  fi
fi

mkdir -p "$OPENFPGA_OUTPUT_DIR"

bash scripts/openfpga_shell.sh \
  -f openfpga/scripts/openfpga_fab_scl1d.tcl
