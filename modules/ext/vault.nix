{ lib, ... }:
let types = lib.types; in
{
  options.app.vault = {
    enable = lib.mkOption { type = types.bool; default = false; description = "Enable Vault sidekick init container and mounts."; };
    address = lib.mkOption { type = types.nullOr types.str; default = null; description = "Vault address (e.g., https://vault.adeo.no)."; };
    kvBasePath = lib.mkOption { type = types.nullOr types.str; default = null; description = "Base KV path prefix (e.g., /kv/preprod/fss)."; };
    authPath = lib.mkOption { type = types.nullOr types.str; default = null; description = "Kubernetes auth login path (e.g., auth/kubernetes/preprod/fss/login)."; };
    sidekickImage = lib.mkOption { type = types.str; default = "navikt/vault-sidekick:latest"; description = "Vault sidekick init container image."; };
    paths = lib.mkOption {
      type = types.listOf (types.submodule ({ ... }: { options = {
        kvPath = lib.mkOption { type = types.str; description = "Full KV path for secret (e.g., /serviceuser/data/test/srvuser)."; };
        mountPath = lib.mkOption { type = types.str; description = "Mount path in container where secret will be materialized."; };
      }; }));
      default = [];
      description = "Additional Vault secret paths to mount.";
    };
  };
}

