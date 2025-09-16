{
  description = "nixerator: generate Kubernetes manifests with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      # System-agnostic library output
      nixeratorLib = import ./lib { lib = nixpkgs.lib; };
    in
      {
        # Expose a single, canonical function to build apps
        lib = nixeratorLib // (let
          baseModules = with self.nixosModules; [
            app
            appAiven
            appVault
            appGcpBuckets
            appGcpCloudSQL
            appGcpBigQuery
            appAzure
            appIDPorten
            appSecureLogs
            appFrontend
            appPDB
            appServiceAccount
            appConfigMap
            appNetworkPolicy
            appAccessPolicy
            appFQDNPolicy
            appPrometheus
            appPodSecurity
            appObservability
            appDefaultEnv
            appTokenX
            appMaskinporten
            appTexas
            appCABundle
            appLogin
            appWebproxy
            appLeaderElection
            appIntegrations
            appReloader
            appTTL
            appLabelsDefaults
            appScheduling
            appHostAliases
          ];
          mkConfigModule = appCfg: { lib, ... }: { config.app = appCfg; };
        in {
          buildApp = { app, extraModules ? [], specialArgs ? {} }:
            nixeratorLib.evalAppModules {
              modules = baseModules ++ extraModules ++ [ (mkConfigModule app) ];
              specialArgs = specialArgs // { lib = nixpkgs.lib; };
            };
        });

        # Expose the app module for consumers
        nixosModules = {
          app = import ./modules/app.nix;
          appAiven = import ./modules/ext/aiven.nix;
          appVault = import ./modules/ext/vault.nix;
          appGcpBuckets = import ./modules/ext/gcp-buckets.nix;
          appGcpCloudSQL = import ./modules/ext/gcp-cloudsql.nix;
          appGcpBigQuery = import ./modules/ext/gcp-bigquery.nix;
          appAzure = import ./modules/ext/azure.nix;
          appIDPorten = import ./modules/ext/idporten.nix;
          appSecureLogs = import ./modules/ext/securelogs.nix;
          appFrontend = import ./modules/ext/frontend.nix;
          appPDB = import ./modules/ext/pdb.nix;
          appServiceAccount = import ./modules/ext/serviceaccount.nix;
          appConfigMap = import ./modules/ext/configmap.nix;
          appNetworkPolicy = import ./modules/ext/networkpolicy.nix;
          appAccessPolicy = import ./modules/ext/accesspolicy.nix;
          appFQDNPolicy = import ./modules/ext/fqdnpolicy.nix;
          appPrometheus = import ./modules/ext/prometheus.nix;
          appPodSecurity = import ./modules/ext/podsecurity.nix;
          appObservability = import ./modules/ext/observability.nix;
          appDefaultEnv = import ./modules/ext/defaultenv.nix;
          appTokenX = import ./modules/ext/tokenx.nix;
          appMaskinporten = import ./modules/ext/maskinporten.nix;
          appTexas = import ./modules/ext/texas.nix;
          appCABundle = import ./modules/ext/cabundle.nix;
          appLogin = import ./modules/ext/login.nix;
          appWebproxy = import ./modules/ext/webproxy.nix;
          appLeaderElection = import ./modules/ext/leaderelection.nix;
          appIntegrations = import ./modules/ext/integrations.nix;
          appReloader = import ./modules/ext/reloader.nix;
          appTTL = import ./modules/ext/ttl.nix;
          appLabelsDefaults = import ./modules/ext/labels-defaults.nix;
          appScheduling = import ./modules/ext/scheduling.nix;
          appHostAliases = import ./modules/ext/hostaliases.nix;
        };
      }
      // flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
          lib = pkgs.lib;
          nlib = import ./lib { inherit lib; };
        in {
          # Canonical example manifests (basic)
          packages.manifests = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app (import ./examples/app-basic.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # Advanced example: filesFrom PVC/EmptyDir, preStop, strategy
          packages.manifests-advanced = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app (import ./examples/app-advanced.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # Everything example: exercises most resource builders
          packages.manifests-everything = let
            eval = nlib.evalAppModules {
              modules = [
                self.nixosModules.app
                self.nixosModules.appAiven
                self.nixosModules.appPDB
                self.nixosModules.appServiceAccount
                self.nixosModules.appConfigMap
                self.nixosModules.appNetworkPolicy
                self.nixosModules.appAccessPolicy
                self.nixosModules.appFQDNPolicy
                self.nixosModules.appPrometheus
                self.nixosModules.appPodSecurity
                self.nixosModules.appObservability
                self.nixosModules.appDefaultEnv
                self.nixosModules.appReloader
                self.nixosModules.appTTL
                self.nixosModules.appLabelsDefaults
                self.nixosModules.appScheduling
                self.nixosModules.appHostAliases
                (import ./examples/app-everything.nix)
              ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # Generate docs from module options
          packages.docs = let
            docModules = with self.nixosModules; [
              app
              appAiven
              appVault
              appGcpBuckets
              appGcpCloudSQL
              appGcpBigQuery
              appAzure
              appIDPorten
              appSecureLogs
              appFrontend
              appPDB
              appServiceAccount
              appConfigMap
              appNetworkPolicy
              appAccessPolicy
              appFQDNPolicy
              appPrometheus
              appPodSecurity
              appObservability
              appDefaultEnv
              appTokenX
              appMaskinporten
              appTexas
              appCABundle
              appLogin
              appWebproxy
              appLeaderElection
              appIntegrations
              appReloader
              appTTL
              appLabelsDefaults
              appScheduling
              appHostAliases
            ];
            eval = lib.evalModules { modules = docModules; specialArgs = { inherit lib; }; };
            org = nlib.orgDocsNoTableFromEval eval;
          in pkgs.writeText "nixerator-options.org" org;

          devShells.default = pkgs.mkShell {
            buildInputs = [
              pkgs.nixpkgs-fmt
              pkgs.yq-go
              pkgs.kubeconform
            ];
          };

          formatter = pkgs.nixpkgs-fmt;
          # Aiven example
          packages.manifests-aiven = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appAiven (import ./examples/app-aiven.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # Azure application example
          packages.manifests-azure-application = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appAzure (import ./examples/app-azure-application.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # Azure sidecar (wonderwall) example
          packages.manifests-azure-sidecar = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appAzure (import ./examples/app-azure-sidecar.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # Azure preauthorized example
          packages.manifests-azure-preauth = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appAccessPolicy self.nixosModules.appAzure (import ./examples/app-azure-preauth.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # Azure preauthorized advanced example
          packages.manifests-azure-preauth-advanced = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appAccessPolicy self.nixosModules.appAzure (import ./examples/app-azure-preauth-advanced.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # IDPorten sidecar example
          packages.manifests-idporten = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appIDPorten (import ./examples/app-idporten.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # AccessPolicy variants
          packages.manifests-access-samens = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appAccessPolicy (import ./examples/app-access-samens.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          packages.manifests-access-egress = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appAccessPolicy (import ./examples/app-access-egress.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # HPA Kafka examples
          packages.manifests-hpa-kafka = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app (import ./examples/app-hpa-kafka.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          packages.manifests-hpa-advanced = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app (import ./examples/app-hpa-advanced.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;
          # Ingress variants
          packages.manifests-ingress-grpc = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app (import ./examples/app-ingress-grpc.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          packages.manifests-ingress-redirects = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app (import ./examples/app-ingress-redirects.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          packages.manifests-frontend = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appFrontend (import ./examples/app-frontend.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          packages.manifests-securelogs = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appSecureLogs (import ./examples/app-securelogs.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          packages.manifests-vault-basic = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appVault (import ./examples/app-vault-basic.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # TokenX example
          packages.manifests-tokenx = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appTokenX (import ./examples/app-tokenx.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # TokenX with access policy example
          packages.manifests-tokenx-access = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appAccessPolicy self.nixosModules.appTokenX (import ./examples/app-tokenx-access.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # TokenX with inbound rules example
          packages.manifests-tokenx-access-rules = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appAccessPolicy self.nixosModules.appTokenX (import ./examples/app-tokenx-access-rules.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # Maskinporten example
          packages.manifests-maskinporten = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appMaskinporten (import ./examples/app-maskinporten.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # Texas example
          packages.manifests-texas = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appTokenX self.nixosModules.appMaskinporten self.nixosModules.appTexas (import ./examples/app-texas.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # CA bundle example
          packages.manifests-cabundle = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appCABundle (import ./examples/app-cabundle.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # Login helper example
          packages.manifests-login = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appLogin (import ./examples/app-login.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          packages.manifests-vault-paths = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appVault (import ./examples/app-vault-paths.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          packages.manifests-gcp-buckets = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appGcpBuckets (import ./examples/app-gcp-buckets.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;
          packages.manifests-gcp-buckets-iam = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appGcpBuckets (import ./examples/app-gcp-buckets-iam.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;
          # GCP CloudSQL example
          packages.manifests-gcp-cloudsql = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appGcpBuckets self.nixosModules.appGcpCloudSQL (import ./examples/app-gcp-cloudsql.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # Webproxy example
          packages.manifests-webproxy = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appWebproxy (import ./examples/app-webproxy.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # Integrations stubs example
          packages.manifests-integrations-stubs = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appIntegrations (import ./examples/app-integrations-stubs.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # Leader election example
          packages.manifests-leader-election = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appLeaderElection (import ./examples/app-leader-election.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          packages.manifests-prom-annotations-advanced = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appPrometheus (import ./examples/app-prom-annotations-advanced.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;
          packages.manifests-prom-annotations-basic = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appPrometheus (import ./examples/app-prom-annotations-basic.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;
          packages.manifests-prom-annotations-disabled = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app self.nixosModules.appPrometheus (import ./examples/app-prom-annotations-disabled.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;
        });
}
