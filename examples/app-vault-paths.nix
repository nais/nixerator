{ lib, ... }:
{
  app = {
    name = "vault-paths";
    namespace = "default";
    image = "nginx:1.25";

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    vault = {
      enable = true;
      address = "https://vault.adeo.no";
      kvBasePath = "/kv/preprod/fss";
      authPath = "auth/kubernetes/preprod/fss/login";
      sidekickImage = "navikt/vault-sidekick:v0.3.10-d122b16";
      paths = [ { kvPath = "/serviceuser/data/test/srvuser"; mountPath = "/secrets/credential/srvuser"; } ];
    };
  };
}

