#!/usr/bin/env bash
set -euo pipefail
for x in bash python3 git; do command -v "$x" >/dev/null || { echo "missing: $x"; exit 1; }; done
openfpga_ok=0
printf 'OpenFPGA: '; if command -v openfpga_shell >/dev/null; then openfpga_ok=1; (openfpga_shell --version 2>/dev/null | head -1 || true); else echo 'not found (use configured image or native installer)'; fi
printf 'VPR: '; command -v vpr >/dev/null && (vpr --version 2>/dev/null | head -1 || true) || echo 'not found'
printf 'Icarus: '; command -v iverilog >/dev/null && (iverilog -V 2>&1 | head -1 || true) || echo 'not found'
if [[ -z "${SCL1D_PDK_ROOT:-}" || ! -d "$SCL1D_PDK_ROOT" ]]; then
  echo 'SCL1D_PDK_ROOT is not installed. Run: make install-pdk ARCHIVE=/path/to/SCL_PDK.zip'; exit 2
fi
for f in "$SCL1D_PDK_ROOT/open_source_scl_c1d/open_pdks/sclc1d/libs.ref/digital_c1d/lef/tech_c1d.lef" "$SCL1D_PDK_ROOT/open_source_scl_c1d/open_pdks/sclc1d/libs.ref/digital_c1d/lef/core_c1d.lef" "$SCL1D_PDK_ROOT/open_source_scl_c1d/open_pdks/sclc1d/libs.ref/digital_c1d/lef/io_c1d.lef" "$SCL1D_PDK_ROOT/open_source_scl_c1d/open_pdks/sclc1d/libs.ref/digital_c1d/lib/nldm_tt_27_1p5.lib" "$SCL1D_PDK_ROOT/open_source_scl_c1d/open_pdks/sclc1d/libs.ref/digital_c1d/verilog/c1d.v"; do
  [[ -f "$f" ]] || { echo "missing PDK file: $f"; exit 3; }
done
if [[ "$openfpga_ok" -eq 0 && "${ALLOW_MISSING_OPENFPGA:-0}" != 1 ]]; then echo 'OpenFPGA is required. Run scripts/install-openfpga-native.sh or recreate the Codespace from .devcontainer.'; exit 4; fi
echo 'doctor: PASS'
