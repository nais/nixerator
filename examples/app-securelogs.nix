{ lib, ... }:
{
  app = {
    name = "securelogs-app";
    namespace = "default";
    image = "nginx:1.25";

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    securelogs.enable = true;
    securelogs.image = "fluentbit-image";
  };
}

