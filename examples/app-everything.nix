{ lib, ... }:
{
  app = {
    name = "kitchen-sink";
    namespace = "default";
    image = "nginx:1.25";
    replicas = 3;

    command = [ "/docker-entrypoint.sh" "nginx" "-g" "daemon off;" ];
    env = { FOO = "bar"; LOG_LEVEL = "debug"; };
    imagePullSecrets = [ "regcred" ];

    service = {
      enable = true;
      port = 80;
      targetPort = 8080;
      type = "ClusterIP";
    };

    ingress = {
      enable = true;
      host = "kitchen.local";
      path = "/";
      pathType = "Prefix";
      tls = null;
    };

    hpa = {
      enable = true;
      minReplicas = 2;
      maxReplicas = 5;
      targetCPUUtilizationPercentage = 75;
    };

    probes = {
      liveness = { path = "/health"; port = null; initialDelaySeconds = 5; periodSeconds = 10; };
      readiness = { path = "/ready"; port = null; };
      startup = { path = "/startup"; port = null; failureThreshold = 30; periodSeconds = 5; };
    };

    resources = {
      requests = { cpu = "200m"; memory = "256Mi"; };
      limits = { cpu = "1"; memory = "512Mi"; };
    };

    filesFrom = [
      { configMap = "app-config"; mountPath = "/etc/app"; }
      { secret = "app-secret"; mountPath = "/etc/secret"; }
      { persistentVolumeClaim = "data-pvc"; mountPath = "/data"; }
      { emptyDir = { medium = "Memory"; }; mountPath = "/tmp"; }
    ];

    preStop.http = { path = "/shutdown"; port = null; };

    strategy = {
      type = "RollingUpdate";
      rollingUpdate = {
        maxSurge = "25%";
        maxUnavailable = 0;
      };
    };

    serviceAccount.enable = true;
    serviceAccount.name = null; # defaults to app name
    serviceAccount.annotations = {
      "iam.gke.io/gcp-service-account" = "svc@project.iam.gserviceaccount.com";
    };

    pdb.enable = true;
    pdb.minAvailable = 1;

    configMaps = {
      "app-config".data = {
        GREETING = "hello";
        FEATURE_FLAG = "on";
      };
      "extra-config".data = {
        FOO = "bar";
      };
    };

    secrets = {
      "app-secret".stringData = { PASSWORD = "s3cr3t"; };
      "api-token".stringData = { TOKEN = "abc123"; };
    };

    networkPolicy = {
      enable = true;
      ingress = [ { from = [ { namespaceSelector = {}; } ]; } ];
      egress = [ { to = [ { namespaceSelector = {}; } ]; } ];
    };

    accessPolicy = {
      enable = true;
      inbound = {
        allowSameNamespace = true;
        allowedNamespaces = [ "kube-system" ];
        allowedApps = [ "frontend" ];
        ports = [ 80 8080 ];
      };
      outbound = {
        allowAll = false;
        allowedNamespaces = [ "kube-system" ];
        allowedCIDRs = [ "10.0.0.0/8" ];
        allowedPorts = [ 443 ];
        allowDNS = true;
        allowedFQDNs = [
          { host = "api.github.com"; ports = [ 443 ]; }
          { host = "storage.googleapis.com"; ports = [ 443 ]; }
        ];
      };
    };

    prometheus = {
      enable = true;
      endpoints = [ { port = "http"; path = "/metrics"; } ];
    };
  };
}

