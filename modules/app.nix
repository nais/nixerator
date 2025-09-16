{ lib, ... }:

let
  types = lib.types;
in
{
  options.app = {
    name = lib.mkOption {
      type = types.str;
      description = "Application name; used for labels and resource names.";
    };

    namespace = lib.mkOption {
      type = types.str;
      default = "default";
      description = "Kubernetes namespace for all resources.";
    };

    image = lib.mkOption {
      type = types.str;
      description = "Container image, e.g. nginx:1.25.";
    };

    replicas = lib.mkOption {
      type = types.int;
      default = 1;
      description = "Deployment replica count.";
    };

    env = lib.mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Environment variables as attrset of strings.";
      example = { FOO = "bar"; LOG_LEVEL = "info"; };
    };

    labels = lib.mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Additional labels applied to all resources.";
    };

    annotations = lib.mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Additional annotations applied to all resources.";
    };

    service = {
      enable = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Expose the app via a ClusterIP Service.";
      };
      port = lib.mkOption {
        type = types.int;
        default = 80;
        description = "Service port number.";
      };
      targetPort = lib.mkOption {
        type = types.int;
        default = 8080;
        description = "Container port to target.";
      };
      type = lib.mkOption {
        type = types.str;
        default = "ClusterIP";
        description = "Service type (ClusterIP, NodePort, LoadBalancer).";
      };
    };

    ingress = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Expose the app via an Ingress rule.";
      };
      host = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Ingress host (required if enabled).";
        example = "hello.local";
      };
      path = lib.mkOption {
        type = types.str;
        default = "/";
        description = "Ingress path.";
      };
      pathType = lib.mkOption {
        type = types.str;
        default = "Prefix";
        description = "Ingress pathType.";
      };
      tls = lib.mkOption {
        type = types.nullOr (types.listOf (types.submodule ({...}: { options = {
          hosts = lib.mkOption { type = types.listOf types.str; default = []; description = "TLS hosts"; }; 
          secretName = lib.mkOption { type = types.str; description = "Secret name for TLS cert"; }; 
        }; })));
        default = null;
        description = "Optional TLS entries for the ingress.";
      };
    };

    hpa = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Enable HorizontalPodAutoscaler for the deployment.";
      };
      minReplicas = lib.mkOption {
        type = types.int;
        default = 1;
        description = "Minimum replicas.";
      };
      maxReplicas = lib.mkOption {
        type = types.int;
        description = "Maximum replicas.";
        example = 5;
      };
      targetCPUUtilizationPercentage = lib.mkOption {
        type = types.int;
        default = 80;
        description = "CPU target utilization percentage.";
      };
    };

    secrets = lib.mkOption {
      type = types.attrsOf (types.submodule ({...}: { options = {
        type = lib.mkOption { type = types.str; default = "Opaque"; description = "Kubernetes Secret type."; };
        data = lib.mkOption { type = types.attrsOf types.str; default = {}; description = "Base64-encoded data entries."; };
        stringData = lib.mkOption { type = types.attrsOf types.str; default = {}; description = "Plaintext data entries (server-side encoded)."; };
      }; }));
      default = {};
      description = "Secrets to create, as an attrset keyed by secret name.";
      example = {
        my-secret = { stringData = { PASSWORD = "s3cr3t"; }; };
      };
    };
  };
}

