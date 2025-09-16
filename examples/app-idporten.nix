{ lib, ... }:
{
  app = {
    name = "idporten";
    namespace = "default";
    image = "nginx:1.25";

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    ingress.enable = true;
    ingress.host = "idporten.local";

    idporten.enable = true;
    idporten.sidecar.enabled = true;
  };
}

