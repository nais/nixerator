{ lib, ... }:
{
  app = {
    name = "hello";
    namespace = "default";
    image = "nginx:1.25";
    replicas = 2;
    env = { FOO = "bar"; };
    labels = {};
    annotations = {};

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

    secrets = {
      example-secret = {
        stringData = { PASSWORD = "s3cr3t"; };
      };
    };
  };
}

