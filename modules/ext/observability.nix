{ lib, ... }:
let types = lib.types; in
{
  options.app.observability = {
    defaultContainer = lib.mkOption { type = types.bool; default = false; description = "Annotate Pod with kubectl.kubernetes.io/default-container = app name."; };
    logformat = lib.mkOption { type = types.str; default = ""; description = "Set nais.io/logformat annotation if non-empty."; };
    logtransform = lib.mkOption { type = types.str; default = ""; description = "Set nais.io/logtransform annotation if non-empty."; };

    autoInstrumentation = {
      enabled = lib.mkOption { type = types.bool; default = false; description = "Enable OpenTelemetry auto-instrumentation annotations and env."; };
      runtime = lib.mkOption { type = types.enum [ "java" "nodejs" "python" "dotnet" ]; default = "java"; description = "Runtime to inject (controls instrumentation.opentelemetry.io/inject-<runtime>)."; };
      appConfig = lib.mkOption { type = types.nullOr types.str; default = null; description = "Instrumentation resource reference (e.g., 'system-namespace/app-config')."; };
      destinations = lib.mkOption {
        type = types.listOf (types.submodule ({ ... }: { options = {
          id = lib.mkOption { type = types.str; description = "Destination id to include in nais.backend attribute."; };
        }; }));
        default = [];
        description = "Optional list of destination ids; included as nais.backend attribute joined by ';'.";
      };
      collector = lib.mkOption {
        type = types.nullOr (types.submodule ({ ... }: { options = {
          namespace = lib.mkOption { type = types.str; description = "Collector namespace (for endpoint + network policy)."; };
          service = lib.mkOption { type = types.str; description = "Collector service name."; };
          port = lib.mkOption { type = types.int; default = 4317; description = "Collector port."; };
          protocol = lib.mkOption { type = types.enum [ "grpc" "http" ]; default = "grpc"; description = "OTLP protocol (grpc or http)."; };
          tls = lib.mkOption { type = types.bool; default = false; description = "When false, set OTEL_EXPORTER_OTLP_INSECURE=true and use http endpoint."; };
          labels = lib.mkOption { type = types.attrsOf types.str; default = {}; description = "Match labels for collector pods (NetworkPolicy egress)."; };
        }; }));
        default = null;
        description = "Collector connection details (endpoint and egress policy).";
      };
    };

    logging = {
      enabled = lib.mkOption { type = types.bool; default = false; description = "Enable logging; when destinations provided, add logs.nais.io flow labels."; };
      destinations = lib.mkOption {
        type = types.listOf (types.submodule ({ ... }: { options = {
          id = lib.mkOption { type = types.str; description = "Destination id (e.g., 'elastic', 'loki')."; };
        }; }));
        default = [];
        description = "Optional list of logging destinations to enable (adds logs.nais.io/flow-<id>=true and disables default flow).";
      };
    };
  };
}
