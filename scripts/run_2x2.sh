#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
cd "$repo_root"

fabric_size="${FABRIC_SIZE:-2x2}"
if [[ ! "$fabric_size" =~ ^[1-9][0-9]*x[1-9][0-9]*$ ]]; then
  echo "Invalid FABRIC_SIZE: $fabric_size (use NxM, e.g. 4x4)" >&2
  exit 2
fi

for f in \
  openfpga/arch/vpr_arch_2x2.xml \
  openfpga/arch/vsd_openfpga_arch_scl1d.xml \
  openfpga/arch/scl1d_simulation_setting.xml \
  openfpga/benchmarks/and2.blif \
  openfpga/benchmarks/and2.v \
  openfpga/benchmarks/and2.act
do
  [[ -f "$f" ]] || { echo "missing $f" >&2; exit 2; }
done

# Each fixed layout includes a one-tile perimeter I/O ring.
python3 - "$repo_root/openfpga/arch/vpr_arch_2x2.xml" "$fabric_size" <<'PY'
import sys
import xml.etree.ElementTree as ET

root = ET.parse(sys.argv[1]).getroot()
name = sys.argv[2]
layout = next(
    (element for element in root.findall('./layout/fixed_layout')
     if element.get('name') == name),
    None,
)
if layout is None:
    sys.exit(f'No fixed_layout named {name!r}; add it to {sys.argv[1]}')

cols, rows = map(int, name.split('x'))
if int(layout.get('width')) != cols + 2 or int(layout.get('height')) != rows + 2:
    sys.exit(f'{name}: fixed_layout width/height must be {cols + 2}/{rows + 2}')
PY

openfpga_bin="$(bash scripts/openfpga_tool.sh --print-path)"
if [[ -z "${OPENFPGA_PATH:-}" ]]; then
  case "$openfpga_bin" in
    */build/openfpga/openfpga)
      export OPENFPGA_PATH="${openfpga_bin%/build/openfpga/openfpga}" ;;
    */build/openfpga)
      export OPENFPGA_PATH="${openfpga_bin%/build/openfpga}" ;;
    *)
      echo "Cannot derive OPENFPGA_PATH from $openfpga_bin" >&2
      exit 2 ;;
  esac
fi

export FABRIC_DEVICE="$fabric_size"
export VPR_ARCH_FILE="$repo_root/openfpga/arch/vpr_arch_2x2.xml"
export OPENFPGA_ARCH_FILE="$repo_root/openfpga/arch/vsd_openfpga_arch_scl1d.xml"
export VPR_TESTBENCH_BLIF="$repo_root/openfpga/benchmarks/and2.blif"
export VPR_TESTBENCH_VERILOG="$repo_root/openfpga/benchmarks/and2.v"
export ACTIVITY_FILE="$repo_root/openfpga/benchmarks/and2.act"
export OPENFPGA_OUTPUT_DIR="$repo_root/results/$fabric_size"
export OPENFPGA_SIM_SETTING_FILE="$repo_root/openfpga/arch/scl1d_simulation_setting.xml"
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
    'FABRIC_DEVICE',
    'VPR_ARCH_FILE',
    'VPR_TESTBENCH_BLIF',
    'OPENFPGA_ARCH_FILE',
    'OPENFPGA_SIM_SETTING_FILE',
    'ACTIVITY_FILE',
    'OPENFPGA_OUTPUT_DIR',
    'VPR_TESTBENCH_VERILOG',
]
for name in variables:
    text = text.replace(f'$::env({name})', os.environ[name])

destination.write_text(text)
PY

bash scripts/openfpga_shell.sh -f "$resolved_tcl" \
  | tee "$OPENFPGA_OUTPUT_DIR/openfpga.log"

if ! grep -Fq 'Finish execution with 0 errors' \
  "$OPENFPGA_OUTPUT_DIR/openfpga.log"; then
  echo "OpenFPGA did not report a successful completion" >&2
  exit 1
fi

python3 scripts/render_fabric.py \
  --arch "$VPR_ARCH_FILE" \
  --device "$fabric_size" \
  --out "$OPENFPGA_OUTPUT_DIR/fabric_arch.svg"

if command -v rsvg-convert >/dev/null 2>&1; then
  rsvg-convert -o "$OPENFPGA_OUTPUT_DIR/fabric_arch.png" \
    "$OPENFPGA_OUTPUT_DIR/fabric_arch.svg"
fi
