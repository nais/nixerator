{ lib, ... }:
{
  app = {
    name = "hello";
    namespace = "default";
    image = "nginx:1.25";

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    accessPolicy = {
      enable = true;
      inbound = {
        allowSameNamespace = true;
        ports = [ 80 ];
      };
      outbound = {
        allowAll = true;
      };
    };
  };
}

