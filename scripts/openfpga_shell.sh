#!/usr/bin/env bash
set -euo pipefail
if command -v openfpga_shell >/dev/null 2>&1; then exec openfpga_shell "$@"; fi
if [[ -x openfpga/OpenFPGA/openfpga_shell ]]; then exec openfpga/OpenFPGA/openfpga_shell "$@"; fi
cat >&2 <<'MSG'
OpenFPGA is not on PATH. Use the configured Codespace image or run scripts/install-openfpga-native.sh.
MSG
exit 2
