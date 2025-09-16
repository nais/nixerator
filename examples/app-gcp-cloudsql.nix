{ lib, ... }:
{
  app = {
    name = "gcp-cloudsql";
    namespace = "default";
    image = "nginx:1.25";

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    gcp = {
      projectId = "team-project-id";
      cloudSql = {
        instances = [ {
          name = "db1";
          databaseVersion = "POSTGRES_14";
          region = "europe-north1";
          tier = "db-f1-micro";
          deletionPolicy = "abandon";
        } ];
        databases = [ { name = "appdb"; instance = "db1"; } ];
        users = [ { name = "app"; instance = "db1"; passwordSecretName = "sql-user-app"; passwordSecretKey = "password"; } ];
      };
    };
  };
}

