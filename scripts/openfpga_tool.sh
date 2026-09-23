#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
cd "$repo_root"

source_candidates=(
  "${OPENFPGA_ENV_FILE:-}"
  "${OPENFPGA_PATH:-}/openfpga.sh"
  "$repo_root/openfpga/OpenFPGA/openfpga.sh"
  "/opt/openfpga/openfpga.sh"
)

for env_file in "${source_candidates[@]}"; do
  if [[ -n "$env_file" && -f "$env_file" ]]; then
    source "$env_file" >/dev/null
    break
  fi
done

binary_candidates=(
  "${OPENFPGA_BIN:-}"
  "${OPENFPGA_PATH:-}/openfpga/openfpga"
  "${OPENFPGA_PATH:-}/openfpga"
  "$repo_root/openfpga/OpenFPGA/openfpga/openfpga"
  "$repo_root/openfpga/OpenFPGA/openfpga"
  "/opt/openfpga/openfpga/openfpga"
  "/opt/openfpga/openfpga"
)

for command_name in openfpga_shell openfpga; do
  command_path="$(type -P "$command_name" 2>/dev/null || true)"
  [[ -n "$command_path" ]] && binary_candidates+=("$command_path")
done

OPENFPGA_BIN_RESOLVED=""

for candidate in "${binary_candidates[@]}"; do
  if [[ -n "$candidate" && -x "$candidate" && ! -d "$candidate" ]]; then
    OPENFPGA_BIN_RESOLVED="$candidate"
    break
  fi
done

if [[ -z "$OPENFPGA_BIN_RESOLVED" ]]; then
  echo "OpenFPGA executable not found." >&2
  echo "OPENFPGA_PATH=${OPENFPGA_PATH:-<unset>}" >&2
  printf 'Checked paths:\n' >&2
  printf '  %s\n' "${binary_candidates[@]}" >&2
  exit 127
fi

if [[ "${1:-}" == "--print-path" ]]; then
  printf '%s\n' "$OPENFPGA_BIN_RESOLVED"
  exit 0
fi

exec "$OPENFPGA_BIN_RESOLVED" "$@"
