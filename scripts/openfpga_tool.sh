#!/usr/bin/env bash
set -euo pipefail

# Resolve the OpenFPGA executable in both supported layouts:
#   prebuilt image: /opt/openfpga/openfpga/openfpga
#   native checkout: openfpga/OpenFPGA/openfpga/openfpga
# The official openfpga.sh is an environment/helper script; it is not the
# executable called openfpga_shell.

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
cd "$repo_root"

source_candidates=(
  "${OPENFPGA_ENV_FILE:-}"
  "${OPENFPGA_PATH:-}/openfpga.sh"
  "$(pwd)/openfpga/OpenFPGA/openfpga.sh"
  "/opt/openfpga/openfpga.sh"
)

for env_file in "${source_candidates[@]}"; do
  if [[ -n "$env_file" && -f "$env_file" ]]; then
    # shellcheck disable=SC1090
    source "$env_file" >/dev/null
    break
  fi
done

binary_candidates=(
  "${OPENFPGA_BIN:-}"
  "${OPENFPGA_PATH:-}/openfpga/openfpga"
  "${OPENFPGA_PATH:-}/openfpga"
  "$(pwd)/openfpga/OpenFPGA/openfpga/openfpga"
  "$(pwd)/openfpga/OpenFPGA/openfpga"
  "/opt/openfpga/openfpga/openfpga"
  "/opt/openfpga/openfpga"
  "${OPENFPGA_PATH:-}/build/openfpga/openfpga"
  "${OPENFPGA_PATH:-}/build/openfpga"
  "/opt/openfpga/build/openfpga/openfpga"
  "/opt/openfpga/build/openfpga"
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
  echo "Checked OPENFPGA_PATH=${OPENFPGA_PATH:-<unset>}" >&2
  printf 'Checked paths:\n' >&2
  printf '  %s\n' "${binary_candidates[@]}" >&2
  exit 127
fi

# Add OpenFPGA build-tree shared libraries for the dynamic loader.
if [[ -n "${OPENFPGA_PATH:-}" && -d "$OPENFPGA_PATH/build" ]]; then
  while IFS= read -r library_dir; do
    case ":${LD_LIBRARY_PATH:-}:" in
      *":$library_dir:"*) ;;
      *) LD_LIBRARY_PATH="$library_dir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ;;
    esac
  done < <(
    find "$OPENFPGA_PATH/build" \
      -type f \
      -name 'lib*.so*' \
      -printf '%h\n' 2>/dev/null
  )

  export LD_LIBRARY_PATH
fi

if [[ "${1:-}" == "--print-path" ]]; then
  printf '%s\n' "$OPENFPGA_BIN_RESOLVED"
  exit 0
fi

exec "$OPENFPGA_BIN_RESOLVED" "$@"
