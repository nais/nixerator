{ lib, ... }:
let
  types = lib.types;
in
{
  options.app.fqdnPolicy = {
    enable = lib.mkOption {
      type = types.bool;
      default = false;
      description = "Emit a GKE FQDNNetworkPolicy (CRD) for domain-based egress.";
    };
    rules = lib.mkOption {
      type = types.listOf (types.submodule ({ ... }: {
        options = {
          host = lib.mkOption { type = types.str; description = "Hostname (FQDN), e.g., api.github.com"; };
          ports = lib.mkOption { type = types.listOf types.int; default = [ 443 ]; description = "TCP ports to allow to host (default [443])."; };
        };
      }));
      default = [];
      description = "List of domain egress rules.";
      example = [ { host = "api.github.com"; ports = [ 443 ]; } ];
    };
  };
}

