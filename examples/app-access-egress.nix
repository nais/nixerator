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
        allowSameNamespace = false;
        ports = [];
      };
      outbound = {
        allowAll = false;
        allowedCIDRs = [ "1.2.3.4/32" "10.0.0.0/8" ];
        allowedPorts = [ 443 8443 ];
        allowDNS = true;
      };
    };
  };
}

