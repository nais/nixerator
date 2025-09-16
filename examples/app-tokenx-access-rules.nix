{ lib, ... }:
{
  app = {
    name = "tokenx-access-rules";
    namespace = "default";
    image = "nginx:1.25";
    clusterName = "mycluster";

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    tokenx.enable = true;
    accessPolicy.enable = true;
    accessPolicy.inbound.rules = [
      { application = "client-a"; namespace = "ns-a"; cluster = "other"; }
      { application = "client-b"; }
    ];
  };
}

