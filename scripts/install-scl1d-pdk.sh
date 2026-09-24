#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
archive="${1:-}"
root="${SCL1D_PDK_ROOT:-$repo_root/pdk/local}"

# SCL_C1D_PDK_17092026: hashes of the nested ZIPs, not the outer ZIP.
expected_digital_sha="28c622ff084f1cdb9aa863898471ec678a2b1713a30915f36e3f31b1a45ce7ef"
expected_pad_sha="13dfee81898863c6922a51afd935088d7f52fdd62ddf65baa9f13ed0504be573"

if [[ -z "$archive" || ! -f "$archive" ]]; then
  echo 'Usage: make install-pdk ARCHIVE="/path/to/SCL 1.2 µm PDK.zip"' >&2
  exit 2
fi

for tool in unzip sha256sum find readlink; do
  command -v "$tool" >/dev/null || {
    echo "missing tool: $tool" >&2
    exit 2
  }
done

archive="$(readlink -f -- "$archive")"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT

unzip -q "$archive" -d "$tmp/outer"

mapfile -d '' -t digital_zips < <(
  find "$tmp/outer" -type f -path '*/Digital_C1D/my_dtech.zip' -print0
)
mapfile -d '' -t pad_zips < <(
  find "$tmp/outer" -type f -path '*/PadFrame_C1D/PadFrame_C1D.zip' -print0
)

if [[ ${#digital_zips[@]} -ne 1 || ${#pad_zips[@]} -ne 1 ]]; then
  echo 'Expected one Digital_C1D/my_dtech.zip and one PadFrame_C1D/PadFrame_C1D.zip.' >&2
  exit 3
fi

digital_sha="$(sha256sum "${digital_zips[0]}")"
digital_sha="${digital_sha%% *}"
pad_sha="$(sha256sum "${pad_zips[0]}")"
pad_sha="${pad_sha%% *}"

if [[ "$digital_sha" != "$expected_digital_sha" ||
      "$pad_sha" != "$expected_pad_sha" ]]; then
  echo 'Archive is not the validated SCL_C1D_PDK_17092026 release.' >&2
  echo "Digital SHA256: $digital_sha" >&2
  echo "Padframe SHA256: $pad_sha" >&2
  exit 3
fi

unzip -q "${digital_zips[0]}" -d "$tmp/digital"
unzip -q "${pad_zips[0]}" -d "$tmp/padframe"

digital_dir="$(
  find "$tmp/digital" -type d \
    -path '*/open_source_scl_c1d/open_pdks/sclc1d/libs.ref/digital_c1d' \
    -print -quit
)"
source_root="${digital_dir%/open_pdks/sclc1d/libs.ref/digital_c1d}"
pad_root="$tmp/padframe/PadFrame_C1D"

if [[ -z "$digital_dir" ||
      ! -f "$source_root/open_pdks/sclc1d/libs.ref/digital_c1d/lib/c1d_core_typ.lib" ||
      ! -f "$pad_root/pad_frame_gds/frame5mmx5mm.gds" ||
      ! -f "$pad_root/pad_frame_cdl/frame5mmx5mm.cdl" ]]; then
  echo 'The September digital library or 5 mm padframe payload is incomplete.' >&2
  exit 3
fi

mkdir -p "$root/padframe"

# Replace the old release so July and September cell views cannot mix.
rm -f -- "$root/.scl1d-release"
rm -rf -- "$root/open_source_scl_c1d" "$root/padframe/PadFrame_C1D"

cp -a -- "$source_root" "$root/"
cp -a -- "$pad_root" "$root/padframe/"

printf 'release=SCL_C1D_PDK_17092026\ndigital_sha256=%s\npadframe_sha256=%s\n' \
  "$digital_sha" "$pad_sha" > "$root/.scl1d-release"

echo "Installed September SCL C1D digital PDK and padframe under $root"
