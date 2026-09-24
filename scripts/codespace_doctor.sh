#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
cd "$repo_root"

for x in bash python3 git unzip sha256sum; do
  command -v "$x" >/dev/null || {
    echo "missing: $x" >&2
    exit 1
  }
done

openfpga_bin="$(bash scripts/openfpga_tool.sh --print-path 2>/dev/null || true)"
printf 'OpenFPGA: %s\n' "${openfpga_bin:-not found}"

printf 'VPR: '
if command -v vpr >/dev/null; then
  vpr --version 2>/dev/null | head -1 || true
else
  echo 'not found'
fi

printf 'Icarus: '
if command -v iverilog >/dev/null; then
  iverilog -V 2>&1 | head -1 || true
else
  echo 'not found'
fi

root="${SCL1D_PDK_ROOT:-$repo_root/pdk/local}"
digital="$root/open_source_scl_c1d/open_pdks/sclc1d/libs.ref/digital_c1d"
pad="$root/padframe/PadFrame_C1D"
version="$root/.scl1d-release"

if [[ ! -f "$version" ]] ||
   ! grep -Fxq 'release=SCL_C1D_PDK_17092026' "$version" ||
   ! grep -Fxq 'digital_sha256=28c622ff084f1cdb9aa863898471ec678a2b1713a30915f36e3f31b1a45ce7ef' "$version" ||
   ! grep -Fxq 'padframe_sha256=13dfee81898863c6922a51afd935088d7f52fdd62ddf65baa9f13ed0504be573' "$version"; then
  echo 'September SCL C1D PDK not installed. Run: make install-pdk ARCHIVE=/path/to/SCL_PDK.zip' >&2
  exit 2
fi

for f in \
  "$digital/lef/tech_c1d.lef" \
  "$digital/lef/core_c1d.lef" \
  "$digital/lef/io_c1d.lef" \
  "$digital/lef/corner_c1d.lef" \
  "$digital/lib/c1d_core_typ.lib" \
  "$digital/lib/c1d_core_min.lib" \
  "$digital/lib/c1d_core_max.lib" \
  "$digital/lib/scl1u_pads_typ.lib" \
  "$digital/lib/scl1u_pads_min.lib" \
  "$digital/lib/scl1u_pads_max.lib" \
  "$digital/verilog/c1d.v" \
  "$digital/cdl/core_iolib_c1d.cdl" \
  "$digital/gds/core_c1d.gds" \
  "$digital/gds/io_c1d.gds" \
  "$pad/pad_frame_gds/frame5mmx5mm.gds" \
  "$pad/pad_frame_cdl/frame5mmx5mm.cdl" \
  "$pad/klayout/gds/io_pad_c1d.gds"; do
  [[ -f "$f" ]] || {
    echo "missing PDK file: $f" >&2
    exit 3
  }
done

[[ -n "$openfpga_bin" ]] || {
  echo 'OpenFPGA executable not found' >&2
  exit 4
}
command -v vpr >/dev/null || {
  echo 'VPR executable not found' >&2
  exit 4
}
command -v iverilog >/dev/null || {
  echo 'Icarus executable not found' >&2
  exit 4
}

echo 'doctor: PASS'
