{ lib, ... }:
{
  app = {
    name = "maskin";
    namespace = "default";
    image = "nginx:1.25";

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    maskinporten.enable = true;
    maskinporten.scopes = {
      consumed = [ "scope:one" "scope:two" ];
      exposed = [ "api/.default" ];
    };
  };
}

