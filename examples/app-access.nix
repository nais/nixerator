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
        allowedNamespaces = [ "other" ];
        allowedApps = [ "frontend" ];
        ports = [ 80 ];
      };
      outbound = {
        allowAll = false;
        allowedNamespaces = [ "kube-system" ];
        allowedCIDRs = [ "10.0.0.0/8" ];
        allowedPorts = [ 443 ];
        allowDNS = true;
      };
    };

    fqdnPolicy = {
      enable = true;
      rules = [ { host = "api.github.com"; ports = [ 443 ]; } ];
    };
  };
}

