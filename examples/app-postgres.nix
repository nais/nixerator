{ lib, ... }:
{
  app = {
    name = "pgdemo";
    namespace = "default";
    image = "nginx:1.25";

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    postgres = {
      enable = true;
      cluster = {
        majorVersion = "14";
        resources = { cpu = "500m"; memory = "512Mi"; diskSize = "10Gi"; };
        highAvailability = false;
      };
      database = { collation = "en_US"; extensions = []; };
    };
  };
}

