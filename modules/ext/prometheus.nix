{ lib, ... }:
let types = lib.types; in
{
  options.app.prometheus = {
    enable = lib.mkOption {
      type = types.bool;
      default = false;
      description = "Create a ServiceMonitor for Prometheus scraping.";
    };
    kind = lib.mkOption {
      type = types.enum [ "PodMonitor" "ServiceMonitor" ];
      default = "PodMonitor";
      description = "Choose which CRD to emit for scraping.";
    };
    endpoints = lib.mkOption {
      type = types.listOf (types.submodule ({ ... }: { options = {
        port = lib.mkOption { type = types.str; default = "http"; description = "Service port name to scrape."; };
        path = lib.mkOption { type = types.str; default = "/metrics"; description = "Metrics path."; };
        interval = lib.mkOption { type = types.nullOr types.str; default = null; description = "Scrape interval (e.g., 30s)."; };
      }; }));
      default = [ { port = "http"; path = "/metrics"; } ];
      description = "List of scrape endpoints.";
    };
    containerPort = lib.mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "Optional container port number for metrics when endpoint.port name differs from 'http'.";
      example = 9090;
    };
    selector = lib.mkOption {
      type = types.attrs;
      default = { matchLabels = {}; };
      description = "Label selector for ServiceMonitor; defaults to app selector.";
      defaultText = "{ matchLabels = { app = cfg.app.name; }; }";
    };
  };
}
