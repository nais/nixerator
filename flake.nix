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
        # Expose library functions as a flake lib
        lib = nixeratorLib // {
          # Simple, consumer-friendly entrypoints that bundle our modules
          simple = let
            baseModules = with self.nixosModules; [
              app
              appPDB
              appServiceAccount
              appConfigMap
              appNetworkPolicy
              appPrometheus
            ];
            mkConfigModule = appCfg: { lib, ... }: { config.app = appCfg; };
          in {
            # Evaluate using bundled modules + optional extras
            eval = { app, extraModules ? [], specialArgs ? {} }:
              let
                eval = nixeratorLib.evalAppModules {
                  modules = baseModules ++ extraModules ++ [ (mkConfigModule app) ];
                  specialArgs = specialArgs // { lib = nixpkgs.lib; };
                };
              in eval;

            # Return YAML from a simple app attrset
            yamlFromApp = app:
              (self.lib.simple.eval { inherit app; }).yaml;

            # Return resources attrset from a simple app attrset
            resourcesFromApp = app:
              (self.lib.simple.eval { inherit app; }).resources;
          };
        };

        # Expose the app module for consumers
        nixosModules = {
          app = import ./modules/app.nix;
          appPDB = import ./modules/ext/pdb.nix;
          appServiceAccount = import ./modules/ext/serviceaccount.nix;
          appConfigMap = import ./modules/ext/configmap.nix;
          appNetworkPolicy = import ./modules/ext/networkpolicy.nix;
          appPrometheus = import ./modules/ext/prometheus.nix;
        };
      }
      // flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
          lib = pkgs.lib;
          nlib = import ./lib { inherit lib; };
        in {
          # Example: build a ready-to-apply manifest bundle via the application module
          packages.manifests-basic = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app (import ./examples/app-basic.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # Example: evaluate NixOS-style modules to manifests
          packages.manifests-module-basic = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app (import ./examples/app-basic.nix) ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # Extended example with additional resource creators
          packages.manifests-module-extended = let
            eval = nlib.evalAppModules {
              modules = [
                self.nixosModules.app
                self.nixosModules.appPDB
                self.nixosModules.appServiceAccount
                self.nixosModules.appConfigMap
                self.nixosModules.appNetworkPolicy
                self.nixosModules.appPrometheus
                (import ./examples/app-extended.nix)
              ];
              specialArgs = { inherit lib; };
            };
          in pkgs.writeText "manifest.yaml" eval.yaml;

          # Generate Emacs Org docs for the module options
          packages.docs-org = let
            eval = lib.evalModules { modules = [ self.nixosModules.app ]; specialArgs = { inherit lib; }; };
            org = nlib.orgDocsFromEval eval;
          in pkgs.writeText "nixerator-options.org" org;

          devShells.default = pkgs.mkShell {
            buildInputs = [
              pkgs.nixpkgs-fmt
              pkgs.yq-go
              pkgs.kubeconform
            ];
          };

          formatter = pkgs.nixpkgs-fmt;

          # Add a simple golden check comparing manifests-basic to golden file
          checks.golden-basic = pkgs.runCommand "golden-basic" {
            buildInputs = [ pkgs.yq-go pkgs.diffutils ];
            src = self.packages.${system}.manifests-basic;
            golden = ./tests/golden/manifests-basic.yaml;
          } ''
            set -euo pipefail
            yq -P -S < "$src" > built.yaml
            yq -P -S < "$golden" > golden.yaml || true
            diff -u golden.yaml built.yaml || { echo "Golden mismatch"; exit 1; }
            cp built.yaml "$out"
          '';

          # Kubeconform checks (offline-friendly flags)
          checks.kubeconform-basic = pkgs.runCommand "kubeconform-basic" {
            buildInputs = [ pkgs.kubeconform ];
            src = self.packages.${system}.manifests-basic;
          } ''
            set -euo pipefail
            kubeconform -strict -ignore-missing-schemas -summary -output pretty -exit-on-error - < "$src" > "$out"
          '';

          checks.kubeconform-module-basic = pkgs.runCommand "kubeconform-module-basic" {
            buildInputs = [ pkgs.kubeconform ];
            src = self.packages.${system}.manifests-module-basic;
          } ''
            set -euo pipefail
            kubeconform -strict -ignore-missing-schemas -summary -output pretty -exit-on-error - < "$src" > "$out"
          '';

          checks.kubeconform-module-extended = pkgs.runCommand "kubeconform-module-extended" {
            buildInputs = [ pkgs.kubeconform ];
            src = self.packages.${system}.manifests-module-extended;
          } ''
            set -euo pipefail
            kubeconform -strict -ignore-missing-schemas -summary -output pretty -exit-on-error - < "$src" > "$out"
          '';
        });
}
