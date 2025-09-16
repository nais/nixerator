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

    command = lib.mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Container entrypoint command array (optional).";
      example = ["/bin/myapp" "--serve"];
    };

    resources = lib.mkOption {
      type = types.submodule ({ ... }: { options = {
        limits = lib.mkOption {
          type = types.attrsOf types.str;
          default = {};
          description = "Resource limits (e.g., cpu = \"500m\", memory = \"256Mi\").";
          example = { cpu = "500m"; memory = "512Mi"; };
        };
        requests = lib.mkOption {
          type = types.attrsOf types.str;
          default = {};
          description = "Resource requests (e.g., cpu = \"100m\", memory = \"128Mi\").";
          example = { cpu = "100m"; memory = "128Mi"; };
        };
      }; });
      default = { limits = {}; requests = {}; };
      description = "Container resource requests/limits.";
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

    # Optional clusterName used by defaultEnv injection
    clusterName = lib.mkOption {
      type = types.str;
      default = "";
      description = "Cluster name for NAIS_* env vars when defaultEnv.enable = true.";
    };

    imagePullSecrets = lib.mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of imagePullSecret names to attach to the Pod spec.";
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
      kafka = lib.mkOption {
        type = types.nullOr (types.submodule ({ ... }: { options = {
          topic = lib.mkOption { type = types.str; description = "Kafka topic to scale on (e.g., '<ns>.<topic>')."; };
          consumerGroup = lib.mkOption { type = types.str; description = "Kafka consumer group name."; };
          threshold = lib.mkOption { type = types.oneOf [ types.int types.str ]; description = "Average group lag threshold to target (int or string)."; };
        }; }));
        default = null;
        description = "Optional Kafka scaling metric for HPA (adds External metric).";
      };
    };

    probes = {
      liveness = lib.mkOption {
        type = types.submodule ({ ... }: { options = {
          path = lib.mkOption { type = types.str; default = ""; description = "HTTP path for liveness probe (empty disables)."; };
          port = lib.mkOption { type = types.nullOr types.int; default = null; description = "Optional port override for liveness probe."; };
          initialDelaySeconds = lib.mkOption { type = types.int; default = 0; description = "Initial delay before first probe."; };
          periodSeconds = lib.mkOption { type = types.int; default = 10; description = "Probe period seconds."; };
          timeoutSeconds = lib.mkOption { type = types.int; default = 1; description = "Probe timeout seconds."; };
          failureThreshold = lib.mkOption { type = types.int; default = 3; description = "Failure threshold."; };
        }; });
        default = { path = ""; port = null; initialDelaySeconds = 0; periodSeconds = 10; timeoutSeconds = 1; failureThreshold = 3; };
        description = "Container liveness probe configuration.";
      };
      readiness = lib.mkOption {
        type = types.submodule ({ ... }: { options = {
          path = lib.mkOption { type = types.str; default = ""; description = "HTTP path for readiness probe (empty disables)."; };
          port = lib.mkOption { type = types.nullOr types.int; default = null; description = "Optional port override for readiness probe."; };
          initialDelaySeconds = lib.mkOption { type = types.int; default = 0; description = "Initial delay before first probe."; };
          periodSeconds = lib.mkOption { type = types.int; default = 10; description = "Probe period seconds."; };
          timeoutSeconds = lib.mkOption { type = types.int; default = 1; description = "Probe timeout seconds."; };
          failureThreshold = lib.mkOption { type = types.int; default = 3; description = "Failure threshold."; };
        }; });
        default = { path = ""; port = null; initialDelaySeconds = 0; periodSeconds = 10; timeoutSeconds = 1; failureThreshold = 3; };
        description = "Container readiness probe configuration.";
      };
      startup = lib.mkOption {
        type = types.submodule ({ ... }: { options = {
          path = lib.mkOption { type = types.str; default = ""; description = "HTTP path for startup probe (empty disables)."; };
          port = lib.mkOption { type = types.nullOr types.int; default = null; description = "Optional port override for startup probe."; };
          initialDelaySeconds = lib.mkOption { type = types.int; default = 0; description = "Initial delay before first probe."; };
          periodSeconds = lib.mkOption { type = types.int; default = 10; description = "Probe period seconds."; };
          timeoutSeconds = lib.mkOption { type = types.int; default = 1; description = "Probe timeout seconds."; };
          failureThreshold = lib.mkOption { type = types.int; default = 3; description = "Failure threshold."; };
        }; });
        default = { path = ""; port = null; initialDelaySeconds = 0; periodSeconds = 10; timeoutSeconds = 1; failureThreshold = 3; };
        description = "Container startup probe configuration.";
      };
    };

    envFrom = lib.mkOption {
      type = types.listOf (types.submodule ({ ... }: { options = {
        configMap = lib.mkOption { type = types.str; default = ""; description = "ConfigMap name to import environment from."; };
        secret = lib.mkOption { type = types.str; default = ""; description = "Secret name to import environment from."; };
      }; }));
      default = [];
      description = "Populate env from ConfigMaps/Secrets using envFrom.";
      example = [ { configMap = "app-config"; } { secret = "app-secret"; } ];
    };

    filesFrom = lib.mkOption {
      type = types.listOf (types.submodule ({ ... }: { options = {
        configMap = lib.mkOption { type = types.str; default = ""; description = "ConfigMap name to mount as files (mutually exclusive with secret/persistentVolumeClaim/emptyDir)."; };
        secret = lib.mkOption { type = types.str; default = ""; description = "Secret name to mount as files (mutually exclusive with configMap/persistentVolumeClaim/emptyDir)."; };
        persistentVolumeClaim = lib.mkOption { type = types.str; default = ""; description = "PVC claim name to mount (mutually exclusive with configMap/secret/emptyDir)."; };
        emptyDir = lib.mkOption {
          type = types.nullOr (types.submodule ({ ... }: { options = {
            medium = lib.mkOption { type = types.nullOr types.str; default = null; description = "Set to 'Memory' to use tmpfs; null or empty for disk-backed."; };
          }; }));
          default = null;
          description = "Use an EmptyDir volume at the mount path (mutually exclusive with configMap/secret/persistentVolumeClaim).";
        };
        mountPath = lib.mkOption { type = types.str; description = "Mount path for files."; };
        readOnly = lib.mkOption { type = types.nullOr types.bool; default = null; description = "Mount readOnly flag; defaults true for ConfigMap/Secret and false for PVC/EmptyDir."; };
      }; }));
      default = [];
      description = "Mount files from ConfigMaps/Secrets at given paths.";
    };

    strategy = {
      type = lib.mkOption {
        type = types.str;
        default = "RollingUpdate";
        description = "Deployment strategy type: RollingUpdate or Recreate.";
      };
      rollingUpdate = lib.mkOption {
        type = types.nullOr (types.submodule ({ ... }: { options = {
          maxSurge = lib.mkOption { type = types.nullOr (types.oneOf [ types.int types.str ]); default = null; description = "Max surge during rolling update (int or percentage string)."; };
          maxUnavailable = lib.mkOption { type = types.nullOr (types.oneOf [ types.int types.str ]); default = null; description = "Max unavailable during rolling update (int or percentage string)."; };
        }; }));
        default = null;
        description = "RollingUpdate tunables; only used when type=RollingUpdate.";
      };
    };

    preStop = lib.mkOption {
      type = types.nullOr (types.submodule ({ ... }: { options = {
        exec = lib.mkOption {
          type = types.nullOr (types.submodule ({ ... }: { options = {
            command = lib.mkOption { type = types.listOf types.str; default = []; description = "PreStop exec command."; };
          }; }));
          default = null;
          description = "Exec-based preStop handler.";
        };
        http = lib.mkOption {
          type = types.nullOr (types.submodule ({ ... }: { options = {
            path = lib.mkOption { type = types.str; default = ""; description = "HTTP path for preStop handler."; };
            port = lib.mkOption { type = types.nullOr types.int; default = null; description = "HTTP port for preStop (defaults to service targetPort)."; };
          }; }));
          default = null;
          description = "HTTP-based preStop handler.";
        };
      }; }));
      default = null;
      description = "Container preStop lifecycle hook (exec or http).";
    };

    terminationGracePeriodSeconds = lib.mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "Pod terminationGracePeriodSeconds (null leaves default).";
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
