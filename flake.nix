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
        lib = nixeratorLib;

        # Expose the app module for consumers
        nixosModules = {
          app = import ./modules/app.nix;
        };
      }
      // flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
          lib = pkgs.lib;
          nlib = import ./lib { inherit lib; };
        in {
          # Example: build a ready-to-apply manifest bundle
          packages.manifests-basic = pkgs.writeText "manifest.yaml"
            (nlib.renderManifests [
              (nlib.mkDeployment {
                name = "hello";
                namespace = "default";
                image = "nginx:1.25";
                replicas = 2;
                env = { FOO = "bar"; };
                ports = [{ name = "http"; containerPort = 8080; }];
              })
              (nlib.mkService {
                name = "hello";
                namespace = "default";
                port = 80;
                targetPort = 8080;
              })
              (nlib.mkIngress {
                name = "hello";
                namespace = "default";
                host = "hello.local";
                servicePort = 80;
              })
            ]);

          # Example: evaluate NixOS-style modules to manifests
          packages.manifests-module-basic = let
            eval = nlib.evalAppModules {
              modules = [ self.nixosModules.app (import ./examples/app-basic.nix) ];
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
            ];
          };

          formatter = pkgs.nixpkgs-fmt;
        });
}
