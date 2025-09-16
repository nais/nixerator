{ lib, ... }:
{
  app = {
    name = "gcp-buckets";
    namespace = "default";
    image = "nginx:1.25";

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    gcp = {
      projectId = "team-project-id";
      buckets = [ { name = "mybucket"; location = "europe-north1"; } ];
    };
  };
}

