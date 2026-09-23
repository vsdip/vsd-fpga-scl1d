#!/usr/bin/env bash
set -euo pipefail
commit="${OPENFPGA_COMMIT:-a05f9d0ce4106120f69de9a8c9fbc197116e4860}"
prefix="${OPENFPGA_HOME:-$(pwd)/openfpga/OpenFPGA}"

if [[ -d "$prefix/.git" ]]; then
  git -C "$prefix" fetch --filter=blob:none origin "$commit"
else
  mkdir -p "$(dirname "$prefix")"
  git clone --filter=blob:none https://github.com/lnis-uofu/OpenFPGA.git "$prefix"
fi

git -C "$prefix" checkout --detach "$commit"
cd "$prefix"
make -j"${JOBS:-2}" all CMAKE_FLAGS='-DOPENFPGA_WITH_TEST=OFF -DOPENFPGA_WITH_SWIG=OFF'

if [[ -x "$prefix/openfpga/openfpga" ]]; then
  echo "OpenFPGA binary: $prefix/openfpga/openfpga"
elif [[ -x "$prefix/openfpga" ]]; then
  echo "OpenFPGA binary: $prefix/openfpga"
else
  echo "Build completed, but the OpenFPGA executable was not found under $prefix" >&2
  exit 4
fi
echo "Environment: source $prefix/openfpga.sh"
