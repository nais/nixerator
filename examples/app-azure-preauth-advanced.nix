{ lib, ... }:
{
  app = {
    name = "azure-preauth-adv";
    namespace = "default";
    image = "nginx:1.25";
    clusterName = "mycluster";

    annotations = { "azure.nais.io/preserve" = "true"; };

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    ingress.enable = true;
    ingress.host = "azure-preauth-adv.local";

    azure.application.enabled = true;

    accessPolicy.enable = true;
    accessPolicy.inbound.rules = [
      { application = "appA"; namespace = "nsA"; cluster = "other"; permissions.roles = [ "role-a" ]; }
      { application = "appB"; namespace = "default"; cluster = "mycluster"; permissions.scopes = [ "scope-b" ]; }
      { application = "appC"; permissions.roles = [ "role-c" ]; permissions.scopes = [ "scope-c1" "scope-c2" ]; }
    ];
  };
}

