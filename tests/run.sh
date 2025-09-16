#!/usr/bin/env bash
set -euo pipefail

# Simple golden test runner for nixerator
# - Builds flake packages and compares their canonicalized YAML to golden files
# - Optionally updates goldens with UPDATE_GOLDEN=1

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
GOLDEN_DIR="$ROOT_DIR/tests/golden"
RESULT="result"

OUTPUT=${OUTPUT:-manifests-basic}
MODULE_OUTPUT=${MODULE_OUTPUT:-manifests-module-basic}
MODULE_EXT_OUTPUT=${MODULE_EXT_OUTPUT:-manifests-module-extended}

YQ=${YQ:-yq}

mkdir -p "$GOLDEN_DIR"

canonicalize() {
  # Pretty-print and sort keys to reduce noise
  "$YQ" -P -S '.'
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

  # Schema validation is covered by flake checks (kubeconform-*).
}

build_and_check "$OUTPUT" "${OUTPUT}.yaml"
build_and_check "$MODULE_OUTPUT" "${MODULE_OUTPUT}.yaml"
build_and_check "$MODULE_EXT_OUTPUT" "${MODULE_EXT_OUTPUT}.yaml"

echo "All tests passed."
