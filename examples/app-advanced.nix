{ lib, ... }:
{
  app = {
    name = "hello";
    namespace = "default";
    image = "nginx:1.25";

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    # Files from different sources
    filesFrom = [
      { configMap = "app-config"; mountPath = "/etc/app"; }
      { secret = "app-secret"; mountPath = "/etc/secret"; }
      { persistentVolumeClaim = "data-pvc"; mountPath = "/data"; }
      { emptyDir = { medium = "Memory"; }; mountPath = "/tmp"; }
    ];

    # Lifecycle preStop hook (HTTP)
    preStop.http = { path = "/shutdown"; port = null; };

    # Deployment strategy override
    strategy.type = "RollingUpdate";
    strategy.rollingUpdate.maxSurge = "25%";
    strategy.rollingUpdate.maxUnavailable = 0;
  };
}

