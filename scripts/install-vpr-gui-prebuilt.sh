#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"

install_root="${VPR_GUI_HOME:-$HOME/.local/opt/vpr-gui}"
bundle_url="https://vsd-labs.sgp1.cdn.digitaloceanspaces.com/vpr-gui-216b5fd211-qt6.9.3-linux-amd64.tar.gz"

[[ "$(dpkg --print-architecture)" == "amd64" ]] || {
  echo "This prebuilt VPR GUI requires an amd64 Codespace." >&2
  exit 2
}

for tool in curl tar dpkg-deb sha256sum ldd; do
  command -v "$tool" >/dev/null || {
    echo "Missing required command: $tool" >&2
    exit 2
  }
done

bin="$install_root/results/vpr_gui/build/vpr/vpr"
qt_root="$install_root/results/vpr_gui/qt6/6.9.3/gcc_64"
runtime_root="$install_root/runtime"
runtime_lib="$runtime_root/usr/lib/x86_64-linux-gnu"

tmp_dir="$(mktemp -d)"
trap 'rm -rf -- "$tmp_dir"' EXIT

if [[ ! -x "$bin" || ! -f "$qt_root/lib/libQt6Core.so.6" ]]; then
  echo "Downloading prebuilt VPR GUI..."
  curl -fL --retry 3 "$bundle_url" -o "$tmp_dir/vpr-gui.tar.gz"
  mkdir -p "$install_root"
  tar -xzf "$tmp_dir/vpr-gui.tar.gz" -C "$install_root"
fi

[[ -x "$bin" && -f "$qt_root/lib/libQt6Core.so.6" ]] || {
  echo "The downloaded archive lacks VPR or its Qt libraries." >&2
  exit 2
}

# Download verified Ubuntu 22.04 amd64 runtime packages without sudo.
fetch_runtime() {
  local filename="$1"
  local sha256="$2"
  local url="$3"

  curl -fL --retry 3 "$url" -o "$tmp_dir/$filename"
  printf '%s  %s\n' "$sha256" "$tmp_dir/$filename" | sha256sum -c -
  mkdir -p "$runtime_root"
  dpkg-deb -x "$tmp_dir/$filename" "$runtime_root"
}

if [[ ! -e "$runtime_lib/libtbb.so.12" ||
      ! -e "$runtime_lib/libtbbmalloc_proxy.so.2" ]]; then
  fetch_runtime \
    libtbb12.deb \
    05981f9120f8fb5c2e5a1e1f2a6017976077500141fc4eaf0d3106be6b793c4a \
    https://archive.ubuntu.com/ubuntu/pool/universe/o/onetbb/libtbb12_2021.5.0-7ubuntu2_amd64.deb

  fetch_runtime \
    libtbbmalloc2.deb \
    7b3bd4bde4c92b17c94d27001c884b285eadb0272dd67b4c5405e1de6af20066 \
    https://archive.ubuntu.com/ubuntu/pool/universe/o/onetbb/libtbbmalloc2_2021.5.0-7ubuntu2_amd64.deb
fi

if [[ ! -e "$runtime_lib/libxcb-cursor.so.0" ]]; then
  fetch_runtime \
    libxcb-cursor0.deb \
    c9b5d1ad4af57397b1bd77e0a92750e34419def134c0282a0836ae9efc07cf64 \
    https://archive.ubuntu.com/ubuntu/pool/universe/x/xcb-util-cursor/libxcb-cursor0_0.1.1-4ubuntu1_amd64.deb
fi

export LD_LIBRARY_PATH="$qt_root/lib:$runtime_lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export QT_QPA_PLATFORM_PLUGIN_PATH="$qt_root/plugins/platforms"

for elf in "$bin" "$qt_root/plugins/platforms/libqxcb.so"; do
  [[ -f "$elf" ]] || {
    echo "Missing binary or Qt plugin: $elf" >&2
    exit 2
  }

  missing="$(ldd "$elf" | grep 'not found' || true)"
  if [[ -n "$missing" ]]; then
    printf 'Missing libraries for %s:\n%s\n' "$elf" "$missing" >&2
    exit 2
  fi
done

# Preserve compatibility with scripts that expect the source-build path.
repo_bin="$repo_root/results/vpr_gui/build/vpr/vpr"
mkdir -p "$(dirname "$repo_bin")"
if [[ ! -e "$repo_bin" ]]; then
  ln -sfn "$bin" "$repo_bin"
fi

"$bin" --version
echo "Prebuilt VPR GUI installed. Run: make view-fabric"
