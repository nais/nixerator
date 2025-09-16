{ lib, ... }:
let types = lib.types; in
{
  options.app.scheduling = {
    tolerations = lib.mkOption {
      type = types.listOf types.attrs;
      default = [];
      description = "List of Tolerations to apply to the Pod.";
      example = [ { key = "dedicated"; operator = "Equal"; value = "gar"; effect = "NoSchedule"; } ];
    };
    antiAffinity = {
      enable = lib.mkOption { type = types.bool; default = false; description = "Enable anti-affinity spread across nodes for pods of the same app."; };
      type = lib.mkOption { type = types.enum [ "required" "preferred" ]; default = "required"; description = "Anti-affinity type: required or preferred."; };
      topologyKey = lib.mkOption { type = types.str; default = "kubernetes.io/hostname"; description = "Topology key for anti-affinity."; };
    };
  };
}

