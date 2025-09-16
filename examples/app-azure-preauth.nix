{ lib, ... }:
{
  app = {
    name = "azure-preauth";
    namespace = "default";
    image = "nginx:1.25";
    clusterName = "mycluster";

    annotations = { "azure.nais.io/preserve" = "true"; };

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    ingress.enable = true;
    ingress.host = "azure-preauth.local";

    azure.application.enabled = true;

    accessPolicy.enable = true;
    accessPolicy.inbound.allowedApps = [ "app1" "app2" ];
  };
}

