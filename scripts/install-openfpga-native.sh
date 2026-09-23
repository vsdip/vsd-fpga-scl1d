#!/usr/bin/env bash
set -euo pipefail
prefix="${OPENFPGA_HOME:-$(pwd)/openfpga/OpenFPGA}"
if [[ -d "$prefix/.git" ]]; then git -C "$prefix" fetch --depth 1 origin master; git -C "$prefix" reset --hard a05f9d0ce4106120f69de9a8c9fbc197116e4860; else
  mkdir -p "$(dirname "$prefix")"; git clone --filter=blob:none https://github.com/lnis-uofu/OpenFPGA.git "$prefix"; git -C "$prefix" checkout a05f9d0ce4106120f69de9a8c9fbc197116e4860
fi
cd "$prefix"; make -j"${JOBS:-2}" all CMAKE_FLAGS='-DOPENFPGA_WITH_TEST=OFF -DOPENFPGA_WITH_SWIG=OFF'
echo "source $prefix/openfpga.sh"
