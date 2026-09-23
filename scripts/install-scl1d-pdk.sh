#!/usr/bin/env bash
set -euo pipefail
archive="${1:-}"
root="${SCL1D_PDK_ROOT:-$(pwd)/pdk/local}"
if [[ -z "$archive" || ! -f "$archive" ]]; then echo 'Usage: SCL1D_PDK_ROOT=/workspaces/vsd-fpga-scl1d/pdk/local make install-pdk ARCHIVE=/path/SCL_PDK.zip'; exit 2; fi
mkdir -p "$root"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
unzip -q "$archive" -d "$tmp"
# The supplied bundle contains a nested digital ZIP; unpack nested payloads.
for _ in 1 2 3; do
  while IFS= read -r -d "" z; do unzip -q -o "$z" -d "$(dirname "$z")"; done < <(find "$tmp" -type f -name "*.zip" -print0)
done
digital=$(find "$tmp" -type d -path '*/open_source_scl_c1d/open_pdks/sclc1d/libs.ref/digital_c1d' | head -1)
if [[ -z "$digital" ]]; then echo 'Could not locate the SCL C1D digital_c1d payload'; exit 3; fi
source_root=$(printf '%s\n' "$digital" | sed 's#/open_pdks/.*##')
mkdir -p "$root"
cp -a "$source_root" "$root/"
echo "Installed SCL 1.2um digital PDK under $root"
