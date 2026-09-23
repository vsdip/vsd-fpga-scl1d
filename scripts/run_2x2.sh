#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
cd "$repo_root"

for f in \
  openfpga/arch/vpr_arch_2x2.xml \
  openfpga/arch/vsd_openfpga_arch_scl1d.xml \
  openfpga/benchmarks/and2.blif \
  openfpga/benchmarks/and2.v \
  openfpga/benchmarks/and2.act
do
  [[ -f "$f" ]] || {
    echo "missing $f" >&2
    exit 2
  }
done

openfpga_bin="$(bash scripts/openfpga_tool.sh --print-path)"

if [[ -z "${OPENFPGA_PATH:-}" ]]; then
  case "$openfpga_bin" in
    */build/openfpga/openfpga)
      export OPENFPGA_PATH="${openfpga_bin%/build/openfpga/openfpga}"
      ;;
    */build/openfpga)
      export OPENFPGA_PATH="${openfpga_bin%/build/openfpga}"
      ;;
    *)
      echo "Cannot derive OPENFPGA_PATH from $openfpga_bin" >&2
      exit 2
      ;;
  esac
fi

export VPR_ARCH_FILE="$repo_root/openfpga/arch/vpr_arch_2x2.xml"
export OPENFPGA_ARCH_FILE="$repo_root/openfpga/arch/vsd_openfpga_arch_scl1d.xml"
export VPR_TESTBENCH_BLIF="$repo_root/openfpga/benchmarks/and2.blif"
export VPR_TESTBENCH_VERILOG="$repo_root/openfpga/benchmarks/and2.v"
export ACTIVITY_FILE="$repo_root/openfpga/benchmarks/and2.act"
export OPENFPGA_VPR_ROUTE_CHAN_WIDTH="20"
export OPENFPGA_OUTPUT_DIR="$repo_root/results/2x2"

if [[ -z "${OPENFPGA_SIM_SETTING_FILE:-}" ]]; then
  OPENFPGA_SIM_SETTING_FILE="$(
    find "$OPENFPGA_PATH" \
      -type f \
      -name 'openfpga_simulation_setting.xml' \
      -print -quit 2>/dev/null
  )"

  if [[ -z "$OPENFPGA_SIM_SETTING_FILE" ]]; then
    echo "OpenFPGA simulation settings file not found under $OPENFPGA_PATH" >&2
    exit 2
  fi

  export OPENFPGA_SIM_SETTING_FILE
fi

mkdir -p "$OPENFPGA_OUTPUT_DIR"

resolved_tcl="$OPENFPGA_OUTPUT_DIR/openfpga_fab_scl1d.resolved.tcl"

python3 - "$repo_root/openfpga/scripts/openfpga_fab_scl1d.tcl" "$resolved_tcl" <<'PY'
import os
import sys
from pathlib import Path

source = Path(sys.argv[1])
destination = Path(sys.argv[2])

text = source.read_text()

variables = [
    "VPR_ARCH_FILE",
    "VPR_TESTBENCH_BLIF",
    "OPENFPGA_ARCH_FILE",
    "OPENFPGA_SIM_SETTING_FILE",
    "ACTIVITY_FILE",
    "OPENFPGA_OUTPUT_DIR",
    "VPR_TESTBENCH_VERILOG",
]

for name in variables:
    value = os.environ[name]
    text = text.replace(f"$::env({name})", value)
destination.write_text(text)
PY

bash scripts/openfpga_shell.sh -f "$resolved_tcl"
