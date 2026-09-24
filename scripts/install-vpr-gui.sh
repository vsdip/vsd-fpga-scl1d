#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"

revision="216b5fd2114040397103773a858b7c546bcbbc76"
gui_root="$repo_root/results/vpr_gui"
source_dir="$gui_root/src"
build_dir="$gui_root/build"
qt_prefix="$gui_root/qt6"
qt_version="${VTR_QT_VERSION:-6.9.3}"
jobs="${VPR_BUILD_JOBS:-2}"

mkdir -p "$gui_root"

# Install packages only if this Codespace does not already have them.
packages=(
  pkg-config bison flex python3-dev python3-venv
  libxml2-utils libtbb-dev libeigen3-dev tcl-dev swig
  libxkbcommon-dev libgl-dev libegl-dev libopengl0
  libegl-mesa0 libgl1-mesa-dri
  libxcb-cursor0 libxcb-icccm4 libxcb-image0
  libxcb-keysyms1 libxcb-render-util0
)

missing=()
for package in "${packages[@]}"; do
  if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null |
       grep -Fxq 'install ok installed'; then
    missing+=("$package")
  fi
done

if ((${#missing[@]})); then
  if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is missing. Rebuild this Codespace from the repository's current .devcontainer." >&2
    exit 2
  fi
  sudo -n apt-get update
  sudo -n env DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"
fi

if [[ ! -d "$source_dir/.git" ]]; then
  if [[ -e "$source_dir" ]]; then
    echo "Existing $source_dir is not a Git checkout; inspect it before retrying." >&2
    exit 2
  fi
  git clone \
    https://github.com/verilog-to-routing/vtr-verilog-to-routing.git \
    "$source_dir"
fi

if [[ "$(git -C "$source_dir" rev-parse HEAD)" != "$revision" ]]; then
  git -C "$source_dir" checkout --detach "$revision"
fi

git -C "$source_dir" submodule update --init --recursive

# This pinned VTR revision uses std::setprecision without including <iomanip>.
draw_source="$source_dir/vpr/src/draw/draw_crit_path.cpp"
if ! grep -Fxq '#include <iomanip>' "$draw_source"; then
  grep -Fxq '#include <sstream>' "$draw_source" || {
    echo "Expected include not found in $draw_source" >&2
    exit 2
  }
  sed -i '/^#include <sstream>$/a #include <iomanip>' "$draw_source"
fi

export VTR_QT_PREFIX="$qt_prefix"
bash "$source_dir/dev/ensure_qt6_sdk.sh"

cmake -S "$source_dir" -B "$build_dir" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="$qt_prefix/$qt_version/gcc_64" \
  -DVPR_USE_EZGL=on \
  -DVTR_IPO_BUILD=off \
  -DWITH_PARMYS=OFF \
  -DSLANG_SYSTEMVERILOG=OFF

cmake --build "$build_dir" --target vpr --parallel "$jobs"

gui_bin="$build_dir/vpr/vpr"
[[ -x "$gui_bin" ]] || {
  echo "GUI VPR executable was not produced: $gui_bin" >&2
  exit 1
}

if ! ldd "$gui_bin" | grep -Fq 'libQt6'; then
  echo "VPR was built without a detectable Qt6 link. Check the CMake graphics message." >&2
  exit 1
fi

echo
echo "GUI-enabled VPR ready: $gui_bin"
echo "Next: make view-fabric"
