{ lib, ... }:
{
  app = {
    name = "frontend-app";
    namespace = "default";
    image = "nginx:1.25";

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    frontend = {
      telemetryUrl = "http://telemetry-collector";
      generatedConfig = { mountPath = "/path/to/nais.js"; };
    };
  };
}

