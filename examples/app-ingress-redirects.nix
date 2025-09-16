{ lib, ... }:
{
  app = {
    name = "ingress-redirects";
    namespace = "default";
    image = "nginx:1.25";

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    ingress = {
      enable = true;
      host = "new.example.local";
      redirects = [
        { from = "https://old.example.local"; to = "https://new.example.local"; }
      ];
    };
  };
}

