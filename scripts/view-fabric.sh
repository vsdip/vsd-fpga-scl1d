#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
fabric_size="${FABRIC_SIZE:-2x2}"

if [[ ! "$fabric_size" =~ ^[1-9][0-9]*x[1-9][0-9]*$ ]]; then
  echo "Invalid FABRIC_SIZE: $fabric_size; use a name such as 2x2." >&2
  exit 2
fi

install_root="${VPR_GUI_HOME:-$HOME/.local/opt/vpr-gui}"
prebuilt_bin="$install_root/results/vpr_gui/build/vpr/vpr"
gui_bin="$repo_root/results/vpr_gui/build/vpr/vpr"

# Also work if the repository symlink has not been created.
if [[ ! -x "$gui_bin" && -x "$prebuilt_bin" ]]; then
  gui_bin="$prebuilt_bin"
fi

arch="$repo_root/openfpga/arch/vpr_arch_2x2.xml"
benchmark="$repo_root/openfpga/benchmarks/and2.blif"

[[ -x "$gui_bin" ]] || {
  echo "GUI-enabled VPR is missing. Run: make install-vpr-gui-prebuilt" >&2
  exit 2
}
[[ -f "$arch" && -f "$benchmark" ]] || {
  echo "VPR architecture or AND2 benchmark is missing." >&2
  exit 2
}

# Supply the libraries shipped with, or downloaded for, the prebuilt GUI.
if [[ -x "$prebuilt_bin" && "$gui_bin" -ef "$prebuilt_bin" ]]; then
  qt_root="$install_root/results/vpr_gui/qt6/6.9.3/gcc_64"
  runtime_lib="$install_root/runtime/usr/lib/x86_64-linux-gnu"

  [[ -d "$qt_root/lib" && -d "$runtime_lib" ]] || {
    echo "VPR GUI runtime is incomplete. Run: make install-vpr-gui-prebuilt" >&2
    exit 2
  }

  export LD_LIBRARY_PATH="$qt_root/lib:$runtime_lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  export QT_QPA_PLATFORM_PLUGIN_PATH="$qt_root/plugins/platforms"
fi

python3 - "$arch" "$fabric_size" <<'PY'
import sys
import xml.etree.ElementTree as ET

arch, name = sys.argv[1:]
root = ET.parse(arch).getroot()
names = {item.get("name") for item in root.findall("./layout/fixed_layout")}

if name not in names:
    raise SystemExit(
        f"No fixed layout named {name!r} in {arch}. "
        "Choose a layout defined in the architecture XML."
    )
PY

output_dir="$repo_root/results/$fabric_size/vpr_gui"
mkdir -p "$output_dir/mesa_cache"

export DISPLAY="${VPR_GUI_DISPLAY:-:1}"
export LANG=C.UTF-8
export LIBGL_ALWAYS_SOFTWARE=1
export MESA_SHADER_CACHE_DIR="$output_dir/mesa_cache"

cd "$output_dir"

exec "$gui_bin" \
  "$arch" \
  "$benchmark" \
  --device "$fabric_size" \
  --clock_modeling route \
  --route_chan_width 100 \
  --absorb_buffer_luts off \
  --skip_sync_clustering_and_routing_results on \
  --disp on
