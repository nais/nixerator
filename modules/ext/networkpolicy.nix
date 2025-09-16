{ lib, ... }:
let
  types = lib.types;
in
{
  options.app.networkPolicy = {
    enable = lib.mkOption {
      type = types.bool;
      default = false;
      description = "Enable a NetworkPolicy for the app pods.";
    };
    policyTypes = lib.mkOption {
      type = types.listOf types.str;
      default = [ "Ingress" "Egress" ];
      description = "Policy types to apply.";
    };
    podSelector = lib.mkOption {
      type = types.attrsOf types.str;
      default = { app = ""; };
      defaultText = "{ app = cfg.app.name; }";
      description = "Pod selector labels; defaults to match the app label.";
    };
    ingress = lib.mkOption {
      type = types.listOf types.attrs;
      default = [];
      description = "Ingress rules passed through to spec.ingress (advanced use).";
    };
    egress = lib.mkOption {
      type = types.listOf types.attrs;
      default = [];
      description = "Egress rules passed through to spec.egress (advanced use).";
    };
  };
}

