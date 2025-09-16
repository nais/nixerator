{
  description = "Kitchen-sink consumer of nixerator (full feature demo)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    # Use a tagged release or your fork/branch as needed
    nixerator.url = "github:nais/nixerator";
  };

  outputs = { self, nixpkgs, nixerator }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          # Build manifests for a feature-rich app using the canonical builder
          manifests = let
            eval = nixerator.lib.buildApp {
              app = {
                name = "kitchen-sink";
                namespace = "default";
                image = "nginx:1.25";
                replicas = 3;

                command = [ "/docker-entrypoint.sh" "nginx" "-g" "daemon off;" ];
                env = { FOO = "bar"; LOG_LEVEL = "debug"; };
                imagePullSecrets = [ "regcred" ];

                service = {
                  enable = true;
                  port = 80;
                  targetPort = 8080;
                  type = "ClusterIP";
                };

                ingress = {
                  enable = true;
                  host = "kitchen.local";
                  path = "/";
                  pathType = "Prefix";
                  tls = null;
                };

                hpa = {
                  enable = true;
                  minReplicas = 2;
                  maxReplicas = 5;
                  targetCPUUtilizationPercentage = 75;
                };

                probes = {
                  liveness = { path = "/health"; port = null; initialDelaySeconds = 5; periodSeconds = 10; };
                  readiness = { path = "/ready"; port = null; };
                  startup = { path = "/startup"; port = null; failureThreshold = 30; periodSeconds = 5; };
                };

                resources = {
                  requests = { cpu = "200m"; memory = "256Mi"; };
                  limits = { cpu = "1"; memory = "512Mi"; };
                };

                filesFrom = [
                  { configMap = "app-config"; mountPath = "/etc/app"; }
                  { secret = "app-secret"; mountPath = "/etc/secret"; }
                  { persistentVolumeClaim = "data-pvc"; mountPath = "/data"; }
                  { emptyDir = { medium = "Memory"; }; mountPath = "/tmp"; }
                ];

                preStop.http = { path = "/shutdown"; port = null; };

                strategy = {
                  type = "RollingUpdate";
                  rollingUpdate = { maxSurge = "25%"; maxUnavailable = 0; };
                };

                pdb = { enable = true; minAvailable = 1; };
                serviceAccount = { enable = true; name = null; annotations = {}; };
                configMaps = {
                  app-config.data = { LOG_LEVEL = "info"; FEATURE_X = "true"; };
                };

                # Fine-grained network policy (optional demo)
                networkPolicy = {
                  enable = true;
                  ingress = [ { from = [ { namespaceSelector = {}; } ]; } ];
                  egress = [ { to = [ { namespaceSelector = {}; } ]; } ];
                };

                # High-level access policy + FQDN policy demo
                accessPolicy = {
                  enable = true;
                  inbound = {
                    allowSameNamespace = true;
                    allowedNamespaces = [ "other" ];
                    allowedApps = [ "frontend" ];
                    ports = [ 80 ];
                  };
                  outbound = {
                    allowAll = false;
                    allowedNamespaces = [ "kube-system" ];
                    allowedCIDRs = [ "10.0.0.0/8" ];
                    allowedPorts = [ 443 ];
                    allowDNS = true;
                    allowedFQDNs = [
                      { host = "api.github.com"; ports = [ 443 ]; }
                      { host = "storage.googleapis.com"; ports = [ 443 ]; }
                    ];
                  };
                };

                fqdnPolicy = {
                  enable = true;
                  rules = [ { host = "api.github.com"; ports = [ 443 ]; } ];
                };

                prometheus = {
                  enable = true;
                  kind = "PodMonitor";
                  endpoints = [ { port = "http"; path = "/metrics"; } ];
                };

                # Defaults and annotations
                labelsDefaults.addTeam = true;
                podSecurity.enable = true;
                observability.defaultContainer = true;
                reloader.enable = true;
                ttl.enable = true;
                ttl.duration = "24h";
                defaultEnv.enable = true;
                clusterName = "dev-cluster";

                # Host aliases
                hostAliases = [ { host = "db.internal"; ip = "10.0.0.10"; } ];
              };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;
        }
      );
    };
}

