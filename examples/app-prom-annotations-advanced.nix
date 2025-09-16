{ lib, ... }:
{
  app = {
    name = "prom-annot-adv";
    namespace = "default";
    image = "nginx:1.25";

    service.port = 80;
    service.targetPort = 11335;

    prometheus = {
      enable = true;
      kind = "Annotations";
      path = "/scrape/path";
      port = "22222";
    };
  };
}

