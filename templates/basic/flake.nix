{
  description = "Example consumer of nixerator's simple entrypoint";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixerator.url = "path:.."; # replace with github:org/nixerator when publishing
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
          manifests = pkgs.writeText "manifest.yaml" (nixerator.lib.simple.yamlFromApp {
            name = "hello";
            namespace = "default";
            image = "nginx:1.25";
            replicas = 2;
            env = { FOO = "bar"; };
            service = { enable = true; port = 80; targetPort = 8080; };
            ingress = { enable = true; host = "hello.local"; };
            hpa = { enable = true; minReplicas = 1; maxReplicas = 4; targetCPUUtilizationPercentage = 80; };
            pdb = { enable = true; minAvailable = 1; };
            serviceAccount = { enable = true; };
            configMaps = { app = { data = { LOG_LEVEL = "info"; }; }; };
            networkPolicy = { enable = true; };
            prometheus = { enable = true; };
          });
        }
      );
    };
}
