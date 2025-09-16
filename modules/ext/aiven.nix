{ lib, ... }:
let
  types = lib.types;
in {
  options.app.aiven = {
    enable = lib.mkOption {
      type = types.bool;
      default = false;
      description = "Enable emitting Aiven resources (AivenApplication and optionally service instances).";
    };

    project = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Aiven project name for managed service instances (e.g., Valkey).";
    };

    rangeCIDR = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "CIDR for Aiven services to allow in egress (appends to accessPolicy.outbound.allowedCIDRs when restricting).";
      example = "35.228.0.0/16";
    };

    manageInstances = lib.mkOption {
      type = types.bool;
      default = false;
      description = "If true, create default Aiven service CRs (e.g., Valkey) for requested instances in this namespace.";
    };

    kafka = lib.mkOption {
      type = types.nullOr (types.submodule ({ ... }: { options = {
        pool = lib.mkOption { type = types.str; description = "Kafka pool name (kafkarator)."; };
        streams = lib.mkOption { type = types.bool; default = false; description = "Request a kafka.nais.io/Stream for streams apps."; };
      }; }));
      default = null;
      description = "Kafka integration via AivenApplication (pool, optional streams).";
    };

    openSearch = lib.mkOption {
      type = types.nullOr (types.submodule ({ ... }: { options = {
        instance = lib.mkOption { type = types.str; description = "OpenSearch instance short name (combined with namespace)."; };
        access = lib.mkOption { type = types.enum [ "read" "write" ]; default = "read"; description = "Access level."; };
      }; }));
      default = null;
      description = "OpenSearch access via AivenApplication.";
    };

    valkey = lib.mkOption {
      type = types.listOf (types.submodule ({ ... }: { options = {
        instance = lib.mkOption { type = types.str; description = "Valkey instance short name."; };
        access = lib.mkOption { type = types.enum [ "read" "write" ]; default = "read"; description = "Access level for the instance."; };
        plan = lib.mkOption { type = types.str; default = "startup-4"; description = "Plan for managed Valkey instance if created."; };
        createInstance = lib.mkOption { type = types.bool; default = false; description = "If true and project is set, emit aiven.io/v1alpha1 Valkey for this instance."; };
      }; }));
      default = [];
      description = "Valkey access via AivenApplication, optionally creating Valkey instances.";
    };

    injectLabel = lib.mkOption {
      type = types.bool;
      default = true;
      description = "Add label aiven=enabled to the Deployment when any Aiven integration is configured.";
    };
  };
}

