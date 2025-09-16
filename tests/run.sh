#!/usr/bin/env bash
set -euo pipefail

# Simple golden test runner for nixerator
# - Builds flake packages and compares their canonicalized YAML to golden files
# - Optionally updates goldens with UPDATE_GOLDEN=1

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
GOLDEN_DIR="$ROOT_DIR/tests/golden"
RESULT="result"

OUTPUT=${OUTPUT:-manifests}
ADV_OUTPUT=${ADV_OUTPUT:-manifests-advanced}
EVERY_OUTPUT=${EVERY_OUTPUT:-manifests-everything}
AIVEN_OUTPUT=${AIVEN_OUTPUT:-manifests-aiven}
AP_SAMENS_OUTPUT=${AP_SAMENS_OUTPUT:-manifests-access-samens}
AP_EGRESS_OUTPUT=${AP_EGRESS_OUTPUT:-manifests-access-egress}
HPA_KAFKA_OUTPUT=${HPA_KAFKA_OUTPUT:-manifests-hpa-kafka}
HPA_ADV_OUTPUT=${HPA_ADV_OUTPUT:-manifests-hpa-advanced}
ING_GRPC_OUTPUT=${ING_GRPC_OUTPUT:-manifests-ingress-grpc}
ING_REDIR_OUTPUT=${ING_REDIR_OUTPUT:-manifests-ingress-redirects}
FRONTEND_OUTPUT=${FRONTEND_OUTPUT:-manifests-frontend}
SECURELOGS_OUTPUT=${SECURELOGS_OUTPUT:-manifests-securelogs}
VAULT_BASIC_OUTPUT=${VAULT_BASIC_OUTPUT:-manifests-vault-basic}
VAULT_PATHS_OUTPUT=${VAULT_PATHS_OUTPUT:-manifests-vault-paths}
GCP_BUCKETS_OUTPUT=${GCP_BUCKETS_OUTPUT:-manifests-gcp-buckets}
GCP_BUCKETS_IAM_OUTPUT=${GCP_BUCKETS_IAM_OUTPUT:-manifests-gcp-buckets-iam}
PROM_ANN_ADV_OUTPUT=${PROM_ANN_ADV_OUTPUT:-manifests-prom-annotations-advanced}
PROM_ANN_BASIC_OUTPUT=${PROM_ANN_BASIC_OUTPUT:-manifests-prom-annotations-basic}
PROM_ANN_DISABLED_OUTPUT=${PROM_ANN_DISABLED_OUTPUT:-manifests-prom-annotations-disabled}
GCP_CLOUDSQL_OUTPUT=${GCP_CLOUDSQL_OUTPUT:-manifests-gcp-cloudsql}
WEBPROXY_OUTPUT=${WEBPROXY_OUTPUT:-manifests-webproxy}
INTEGRATIONS_STUBS_OUTPUT=${INTEGRATIONS_STUBS_OUTPUT:-manifests-integrations-stubs}
LEADER_ELECTION_OUTPUT=${LEADER_ELECTION_OUTPUT:-manifests-leader-election}
AZURE_APP_OUTPUT=${AZURE_APP_OUTPUT:-manifests-azure-application}
AZURE_SIDECAR_OUTPUT=${AZURE_SIDECAR_OUTPUT:-manifests-azure-sidecar}
AZURE_PREAUTH_OUTPUT=${AZURE_PREAUTH_OUTPUT:-manifests-azure-preauth}
AZURE_PREAUTH_ADV_OUTPUT=${AZURE_PREAUTH_ADV_OUTPUT:-manifests-azure-preauth-advanced}
IDPORTEN_OUTPUT=${IDPORTEN_OUTPUT:-manifests-idporten}
TOKENX_OUTPUT=${TOKENX_OUTPUT:-manifests-tokenx}
TOKENX_ACCESS_OUTPUT=${TOKENX_ACCESS_OUTPUT:-manifests-tokenx-access}
TOKENX_ACCESS_RULES_OUTPUT=${TOKENX_ACCESS_RULES_OUTPUT:-manifests-tokenx-access-rules}
MASKINPORTEN_OUTPUT=${MASKINPORTEN_OUTPUT:-manifests-maskinporten}
TEXAS_OUTPUT=${TEXAS_OUTPUT:-manifests-texas}
CABUNDLE_OUTPUT=${CABUNDLE_OUTPUT:-manifests-cabundle}
LOGIN_OUTPUT=${LOGIN_OUTPUT:-manifests-login}
POSTGRES_OUTPUT=${POSTGRES_OUTPUT:-manifests-postgres}

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

  # Schema validation is covered by flake checks (kubeconform-*).
}

build_and_check "$OUTPUT" "${OUTPUT}.yaml"
build_and_check "$ADV_OUTPUT" "${ADV_OUTPUT}.yaml"
build_and_check "$EVERY_OUTPUT" "${EVERY_OUTPUT}.yaml"
build_and_check "$AIVEN_OUTPUT" "${AIVEN_OUTPUT}.yaml"
build_and_check "$AP_SAMENS_OUTPUT" "${AP_SAMENS_OUTPUT}.yaml"
build_and_check "$AP_EGRESS_OUTPUT" "${AP_EGRESS_OUTPUT}.yaml"
build_and_check "$HPA_KAFKA_OUTPUT" "${HPA_KAFKA_OUTPUT}.yaml"
build_and_check "$HPA_ADV_OUTPUT" "${HPA_ADV_OUTPUT}.yaml"
build_and_check "$ING_GRPC_OUTPUT" "${ING_GRPC_OUTPUT}.yaml"
build_and_check "$ING_REDIR_OUTPUT" "${ING_REDIR_OUTPUT}.yaml"
build_and_check "$FRONTEND_OUTPUT" "${FRONTEND_OUTPUT}.yaml"
build_and_check "$SECURELOGS_OUTPUT" "${SECURELOGS_OUTPUT}.yaml"
build_and_check "$VAULT_BASIC_OUTPUT" "${VAULT_BASIC_OUTPUT}.yaml"
build_and_check "$VAULT_PATHS_OUTPUT" "${VAULT_PATHS_OUTPUT}.yaml"
build_and_check "$GCP_BUCKETS_OUTPUT" "${GCP_BUCKETS_OUTPUT}.yaml"
build_and_check "$GCP_BUCKETS_IAM_OUTPUT" "${GCP_BUCKETS_IAM_OUTPUT}.yaml"
build_and_check "$PROM_ANN_ADV_OUTPUT" "${PROM_ANN_ADV_OUTPUT}.yaml"
build_and_check "$PROM_ANN_BASIC_OUTPUT" "${PROM_ANN_BASIC_OUTPUT}.yaml"
build_and_check "$PROM_ANN_DISABLED_OUTPUT" "${PROM_ANN_DISABLED_OUTPUT}.yaml"
build_and_check "$GCP_CLOUDSQL_OUTPUT" "${GCP_CLOUDSQL_OUTPUT}.yaml"
build_and_check "$WEBPROXY_OUTPUT" "${WEBPROXY_OUTPUT}.yaml"
build_and_check "$INTEGRATIONS_STUBS_OUTPUT" "${INTEGRATIONS_STUBS_OUTPUT}.yaml"
build_and_check "$LEADER_ELECTION_OUTPUT" "${LEADER_ELECTION_OUTPUT}.yaml"
build_and_check "$AZURE_APP_OUTPUT" "${AZURE_APP_OUTPUT}.yaml"
build_and_check "$AZURE_SIDECAR_OUTPUT" "${AZURE_SIDECAR_OUTPUT}.yaml"
build_and_check "$AZURE_PREAUTH_OUTPUT" "${AZURE_PREAUTH_OUTPUT}.yaml"
build_and_check "$AZURE_PREAUTH_ADV_OUTPUT" "${AZURE_PREAUTH_ADV_OUTPUT}.yaml"
build_and_check "$IDPORTEN_OUTPUT" "${IDPORTEN_OUTPUT}.yaml"
build_and_check "$TOKENX_OUTPUT" "${TOKENX_OUTPUT}.yaml"
build_and_check "$TOKENX_ACCESS_OUTPUT" "${TOKENX_ACCESS_OUTPUT}.yaml"
build_and_check "$TOKENX_ACCESS_RULES_OUTPUT" "${TOKENX_ACCESS_RULES_OUTPUT}.yaml"
build_and_check "$MASKINPORTEN_OUTPUT" "${MASKINPORTEN_OUTPUT}.yaml"
build_and_check "$TEXAS_OUTPUT" "${TEXAS_OUTPUT}.yaml"
build_and_check "$CABUNDLE_OUTPUT" "${CABUNDLE_OUTPUT}.yaml"
build_and_check "$LOGIN_OUTPUT" "${LOGIN_OUTPUT}.yaml"
build_and_check "$POSTGRES_OUTPUT" "${POSTGRES_OUTPUT}.yaml"

echo "All tests passed."
