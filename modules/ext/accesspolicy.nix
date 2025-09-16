{ lib, ... }:
let
  types = lib.types;
in
{
  options.app.accessPolicy = {
    enable = lib.mkOption {
      type = types.bool;
      default = false;
      description = "Enable generation of a NetworkPolicy from high-level access rules.";
    };

    inbound = {
      allowSameNamespace = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Allow traffic from all pods in the same namespace.";
      };
      allowedNamespaces = lib.mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional namespaces allowed to reach this app.";
        example = [ "team-a" "team-b" ];
      };
      allowedApps = lib.mkOption {
        type = types.listOf types.str;
        default = [];
        description = "App names in the same namespace allowed to reach this app.";
        example = [ "api-gateway" "cron" ];
      };
      ports = lib.mkOption {
        type = types.listOf types.int;
        default = [];
        description = "Optional list of allowed service ports for inbound rules (empty means any).";
        example = [ 80 443 ];
      };
    };

    outbound = {
      allowAll = lib.mkOption {
        type = types.bool;
        default = true;
        description = "If true, do not restrict egress (no Egress policy type emitted).";
      };
      allowedNamespaces = lib.mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Namespaces this app may contact when egress is restricted.";
      };
      allowedCIDRs = lib.mkOption {
        type = types.listOf types.str;
        default = [];
        description = "CIDR blocks this app may contact when egress is restricted.";
        example = [ "10.0.0.0/8" "192.168.0.0/16" ];
      };
      allowedPorts = lib.mkOption {
        type = types.listOf types.int;
        default = [];
        description = "Optional list of allowed destination ports for egress (empty means any to allowed peers).";
      };
      allowDNS = lib.mkOption {
        type = types.bool;
        default = true;
        description = "When restricting egress, always allow UDP/53 (DNS) to anywhere.";
      };

      allowedFQDNs = lib.mkOption {
        type = types.listOf (types.submodule ({ ... }: { options = {
          host = lib.mkOption { type = types.str; description = "Allowed egress hostname (FQDN)."; };
          ports = lib.mkOption { type = types.listOf types.int; default = [ 443 ]; description = "TCP ports to allow to host (default [443])."; };
        }; }));
        default = [];
        description = "Domain-based egress that will be emitted as FQDNNetworkPolicy rules.";
      };
    };
  };
}
