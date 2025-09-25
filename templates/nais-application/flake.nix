{
  description = "Demo: build a Naiserator Application (nais.io/v1alpha1) from nixerator app module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    # For local development against this repo, use a path reference.
    # When copying this template out to your own repo, switch to a GitHub tag.
    nixerator.url = "path:../..";
    # nixerator.url = "github:nais/nixerator"; # <- use this outside this repo
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
          # Build an application.nais.io-style manifest (Application kind)
          app = let
            built = nixerator.lib.buildNaisApplication {
              app = {
                name = "myapplication";
                namespace = "myteam";
                image = "navikt/testapp:69.0.0";

                service = { enable = true; port = 80; targetPort = 8080; };
                ingress = { enable = true; host = "myapplication.nav.no"; };

                # Inbound/outbound access policy (subset)
                accessPolicy = {
                  enable = true;
                  inbound.rules = [
                    { application = "app1"; }
                    { application = "app2"; namespace = "q1"; }
                    { application = "app3"; namespace = "q2"; cluster = "dev-gcp"; }
                  ];
                  outbound = {
                    allowAll = false;
                    allowedFQDNs = [
                      { host = "external-application.example.com"; ports = [ 443 ]; }
                      { host = "non-http-service.example.com"; ports = [ 9200 ]; }
                    ];
                  };
                };

                # Env and files
                env = {
                  MY_CUSTOM_VAR = "some_value";
                };
                envFrom = [
                  { secret = "my-secret-with-envs"; }
                  { configMap = "my-configmap-with-envs"; }
                ];
                filesFrom = [
                  { configMap = "example-files-configmap"; mountPath = "/var/run/configmaps"; }
                  { secret = "my-secret-file"; mountPath = "/var/run/secrets"; }
                  { emptyDir = { medium = "Memory"; }; mountPath = "/var/cache"; }
                  { persistentVolumeClaim = "pvc-name"; mountPath = "/var/run/pvc"; }
                ];

                # Probes and lifecycle
                probes = {
                  liveness = { path = "/isalive"; port = 8080; initialDelaySeconds = 20; periodSeconds = 5; timeoutSeconds = 1; failureThreshold = 10; };
                  readiness = { path = "/isready"; port = 8080; initialDelaySeconds = 20; periodSeconds = 5; timeoutSeconds = 1; failureThreshold = 10; };
                  startup = { path = "/started"; port = 8080; initialDelaySeconds = 20; periodSeconds = 5; timeoutSeconds = 1; failureThreshold = 10; };
                };
                preStop.http = { path = "/internal/stop"; port = 8080; };

                # Extras (subset mapping supported)
                leaderElection.enable = true;
                login = { enable = true; provider = "openid"; enforce = { enabled = true; excludePaths = [ "/some/path" "/api/**" ]; }; };
                prometheus = { enable = true; path = "/metrics"; port = "8080"; };

                # Sidecars and integrations (demonstration)
                azure = {
                  application = { enabled = true; tenant = "nav.no"; allowAllUsers = true; claims = { groups = [ { id = "00000000-0000-0000-0000-000000000000"; } ]; }; };
                  sidecar = { enabled = true; autoLogin = true; autoLoginIgnorePaths = [ "/path" "/internal/*" ]; };
                };
                idporten = { enable = true; sidecar = { enabled = true; autoLogin = true; autoLoginIgnorePaths = [ "/path" "/internal/*" ]; level = "idporten-loa-high"; locale = "nb"; }; };
                aiven = { kafka = { pool = "nav-dev"; streams = true; }; valkey = [ { instance = "cache"; access = "write"; } ]; };

                # Resources and scaling
                replicas = 2;
                resources = {
                  requests = { cpu = "200m"; memory = "256Mi"; };
                  limits = { cpu = "500m"; memory = "512Mi"; };
                };
                strategy = { type = "RollingUpdate"; rollingUpdate = { maxSurge = "25%"; maxUnavailable = 0; }; };
              };
            };
          in pkgs.writeText "app.yaml" built.yaml;
        }
      );
    };
}
