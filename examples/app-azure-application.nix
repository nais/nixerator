{ lib, ... }:
{
  app = {
    name = "azure-app";
    namespace = "default";
    image = "nginx:1.25";

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    ingress.enable = true;
    ingress.host = "azure-app.local";

    azure.application = {
      enabled = true;
      tenant = "nav.no";
      singlePageApplication = false;
      allowAllUsers = false;
    };
  };
}

