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
        });
}
