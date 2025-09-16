{ lib, ... }:
{
  app = {
    name = "hello";
    namespace = "default";
    image = "nginx:1.25";
    replicas = 2;
    env = { FOO = "bar"; };

    service = {
      enable = true;
      port = 80;
      targetPort = 8080;
      type = "ClusterIP";
    };

    ingress = {
      enable = true;
      host = "hello.local";
      path = "/";
      pathType = "Prefix";
      tls = null;
    };

    hpa = {
      enable = true;
      minReplicas = 1;
      maxReplicas = 4;
      targetCPUUtilizationPercentage = 80;
    };

    pdb.enable = true;
    pdb.minAvailable = 1;

    serviceAccount.enable = true;
    serviceAccount.name = null; # defaults to app name
    serviceAccount.annotations = {};

    configMaps = {
      app-config.data = {
        LOG_LEVEL = "info";
        FEATURE_X = "true";
      };
    };

    networkPolicy = {
      enable = true;
      # allow all ingress within namespace for demo
      ingress = [ { from = [ { namespaceSelector = {}; } ]; } ];
      # block all egress except DNS
      egress = [
        { to = [ { namespaceSelector = {}; } ]; ports = [ { protocol = "UDP"; port = 53; } ]; }
      ];
    };

    prometheus = {
      enable = true;
      endpoints = [ { port = "http"; path = "/metrics"; } ];
    };
  };
}

