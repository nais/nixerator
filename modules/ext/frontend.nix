{ lib, ... }:
let types = lib.types; in
{
  options.app.frontend = {
    telemetryUrl = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Telemetry collector URL (e.g., http://telemetry-collector). Injected as NAIS_FRONTEND_TELEMETRY_COLLECTOR_URL and into generated config.";
    };
    generatedConfig = lib.mkOption {
      type = types.nullOr (types.submodule ({ ... }: { options = {
        mountPath = lib.mkOption { type = types.str; description = "Mount path for generated nais.js"; };
      }; }));
      default = null;
      description = "Generate a frontend config ConfigMap (nais.js) and mount it to the container.";
    };
  };
}

