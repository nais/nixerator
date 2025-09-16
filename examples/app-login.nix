{ lib, ... }:
{
  app = {
    name = "login";
    namespace = "default";
    image = "nginx:1.25";

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    ingress.enable = true;
    ingress.host = "login.local";

    login = {
      enable = true;
      provider = "idporten";
      enforce = { enabled = true; excludePaths = [ "/internal/*" ]; };
    };
  };
}

