{ lib, ... }:
{
  app = {
    name = "tokenx";
    namespace = "default";
    image = "nginx:1.25";

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    tokenx.enable = true;
  };
}

