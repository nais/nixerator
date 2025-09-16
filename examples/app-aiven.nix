{ lib, ... }:
{
  app = {
    name = "aiven-demo";
    namespace = "default";
    image = "nginx:1.25";

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    # Aiven integrations
    aiven = {
      enable = true;
      project = "dev-project";
      rangeCIDR = null; # e.g., "35.228.0.0/16" to auto-allow egress when accessPolicy restricts
      manageInstances = true; # emit aiven.io Valkey CRs for requested instances

      kafka = null; # or { pool = "some-kafka-pool"; streams = false; secretName = "aiven-kafka"; }

      openSearch = {
        instance = "naistest";
        access = "read";
        secretName = "aiven-opensearch";
      };

      valkey = [
        { instance = "naistest1"; access = "read"; plan = "startup-4"; createInstance = true; secretName = "aiven-valkey-naistest1"; }
        { instance = "naistest2"; access = "write"; plan = "startup-4"; createInstance = true; secretName = "aiven-valkey-naistest2"; }
      ];
    };
  };
}
