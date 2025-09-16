{ lib, ... }:
{
  app = {
    name = "azure-sidecar";
    namespace = "default";
    image = "nginx:1.25";

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    ingress.enable = true;
    ingress.host = "azure-sidecar.local";

    azure.sidecar = {
      enabled = true;
      image = "ghcr.io/nais/wonderwall:latest";
      autoLogin = true;
      autoLoginIgnorePaths = [ "/internal/*" ];
    };
  };
}

