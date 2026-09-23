#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$(cd -- "$script_dir/.." && pwd)"
for x in bash python3 git; do command -v "$x" >/dev/null || { echo "missing: $x"; exit 1; }; done
if [[ -z "${SCL1D_PDK_ROOT:-}" && -d "$(pwd)/pdk/local" ]]; then
  export SCL1D_PDK_ROOT="$(pwd)/pdk/local"
fi
openfpga_ok=0
printf 'OpenFPGA: '
openfpga_bin="$(bash scripts/openfpga_tool.sh --print-path 2>/dev/null || true)"
if [[ -n "$openfpga_bin" ]]; then
  openfpga_ok=1
  printf '%s\n' "$openfpga_bin"
else
  echo 'not found (use configured image or native installer)'
fi
printf 'VPR: '; command -v vpr >/dev/null && (vpr --version 2>/dev/null | head -1 || true) || echo 'not found'
printf 'Icarus: '; command -v iverilog >/dev/null && (iverilog -V 2>&1 | head -1 || true) || echo 'not found'
if [[ -z "${SCL1D_PDK_ROOT:-}" || ! -d "$SCL1D_PDK_ROOT" ]]; then
  echo 'SCL1D_PDK_ROOT is not installed. Run: make install-pdk ARCHIVE=/path/to/SCL_PDK.zip'; exit 2
fi
PDK_DIGITAL="$SCL1D_PDK_ROOT/open_source_scl_c1d/open_pdks/sclc1d/libs.ref/digital_c1d"
for f in \
  "$PDK_DIGITAL/lef/tech_c1d.lef" \
  "$PDK_DIGITAL/lef/core_c1d.lef" \
  "$PDK_DIGITAL/lef/io_c1d.lef" \
  "$PDK_DIGITAL/lef/corner_c1d.lef" \
  "$PDK_DIGITAL/lib/nldm_tt_27_1p5.lib" \
  "$PDK_DIGITAL/lib/nldm_ff_m25_1p55.lib" \
  "$PDK_DIGITAL/lib/nldm_ss_125_2p45.lib" \
  "$PDK_DIGITAL/verilog/c1d.v" \
  "$PDK_DIGITAL/cdl/core_iolib_c1d.cdl" \
  "$PDK_DIGITAL/gds/core_c1d.gds" \
  "$PDK_DIGITAL/gds/io_c1d.gds"; do
  [[ -f "$f" ]] || { echo "missing PDK file: $f"; exit 3; }
done
if [[ "$openfpga_ok" -eq 0 && "${ALLOW_MISSING_OPENFPGA:-0}" != 1 ]]; then echo 'OpenFPGA is required. Run scripts/install-openfpga-native.sh or recreate the Codespace from .devcontainer.'; exit 4; fi
echo 'doctor: PASS'
