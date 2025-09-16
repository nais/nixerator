{ lib, ... }:
{
  app = {
    name = "gcp-iam";
    namespace = "default";
    image = "nginx:1.25";

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    gcp = {
      projectId = "team-project-id";
      googleProjectId = "google-project-id";
      buckets = [ { name = "mybucket"; } ];
      iam = {
        createServiceAccount = true;
        enableWorkloadIdentityBinding = true;
        grantBucketViewer = true;
      };
    };
  };
}

