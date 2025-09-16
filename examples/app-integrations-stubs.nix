{ lib, ... }:
{
  app = {
    name = "integrations";
    namespace = "default";
    image = "nginx:1.25";

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    integrations = {
      wonderwall.enabled = true;
      azure = { enabled = true; clientId = "00000000-0000-0000-0000-000000000000"; };
      texas.enabled = true;
      tokenx = { enabled = true; clientId = "cluster:namespace:integrations"; };
      maskinporten = { enabled = true; clientId = "maskin-client"; };
    };
  };
}

