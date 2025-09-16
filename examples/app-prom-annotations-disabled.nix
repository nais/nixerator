{ lib, ... }:
{
  app = {
    name = "prom-annot-disabled";
    namespace = "default";
    image = "nginx:1.25";

    service.port = 80;
    service.targetPort = 11335;

    prometheus = {
      enable = false;
      kind = "Annotations";
      path = "/scrape/path";
    };
  };
}

