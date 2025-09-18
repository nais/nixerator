#!/usr/bin/env bash
set -euo pipefail

# Simple golden test runner for nixerator
# - Builds flake packages and compares their canonicalized YAML to golden files
# - Optionally updates goldens with UPDATE_GOLDEN=1

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
GOLDEN_DIR="$ROOT_DIR/tests/golden"
RESULT="result"

MANIFEST_PACKAGES=${MANIFEST_PACKAGES:-}

YQ=${YQ:-yq}

mkdir -p "$GOLDEN_DIR"

canonicalize() {
  # Pretty-print and sort keys recursively to reduce noise
  "$YQ" -P 'sort_keys(..)'
}

compare_or_update() {
  local built_file="$1"; shift
  local golden_file="$1"; shift

  if [[ "${UPDATE_GOLDEN:-0}" == "1" ]]; then
    canonicalize < "$built_file" > "$golden_file"
    echo "updated golden: $golden_file"
    return 0
  fi

  tmp_built=$(mktemp)
  tmp_golden=$(mktemp)
  canonicalize < "$built_file" > "$tmp_built"
  canonicalize < "$golden_file" > "$tmp_golden" || true
  if ! diff -u "$tmp_golden" "$tmp_built"; then
    echo "Mismatch: $golden_file" >&2
    exit 1
  fi
}

build_and_check() {
  local pkg="$1"; shift
  local golden_name="$1"; shift

  echo "Building $pkg..."
  nix build ".#$pkg"
  local built_yaml="$RESULT"

  local golden_file="$GOLDEN_DIR/$golden_name"
  if [[ ! -f "$golden_file" && "${UPDATE_GOLDEN:-0}" != "1" ]]; then
    echo "Golden not found: $golden_file (run UPDATE_GOLDEN=1 $0)" >&2
    exit 1
  fi

  compare_or_update "$built_yaml" "$golden_file"

  # Schema validation not run in flake checks (offline). Run kubeconform manually if desired.
}

# Determine manifest package names dynamically (prefix "manifests").
names=()
if [[ -n "$MANIFEST_PACKAGES" ]]; then
  # Allow an override list via env var (space-separated)
  read -r -a names <<< "$MANIFEST_PACKAGES"
else
  # Derive current system from uname to avoid relying on builtins.currentSystem
  uname_s=$(uname -s)
  uname_m=$(uname -m)
  case "$uname_s" in
    Linux) os="linux" ;;
    Darwin) os="darwin" ;;
    *) echo "Unsupported OS: $uname_s" >&2; exit 1 ;;
  esac
  case "$uname_m" in
    x86_64|amd64) arch="x86_64" ;;
    arm64|aarch64) arch="aarch64" ;;
    *) echo "Unsupported arch: $uname_m" >&2; exit 1 ;;
  esac
  sys="${arch}-${os}"
  while IFS= read -r name; do
    [[ -n "$name" ]] && names+=("$name")
  done < <(nix eval --json ".#packages.$sys" | "$YQ" -r 'keys | .[]' | grep '^manifests')
fi

for pkg in "${names[@]}"; do
  build_and_check "$pkg" "${pkg}.yaml"
done

echo "All tests passed."
