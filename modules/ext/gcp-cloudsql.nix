{ lib, ... }:
let
  types = lib.types;
in {
  options.app.gcp.cloudSql = {
      instances = lib.mkOption {
        type = types.listOf (types.submodule ({ ... }: {
          options = {
            name = lib.mkOption { type = types.str; description = "SQL instance name"; };
            databaseVersion = lib.mkOption { type = types.str; description = "Database version, e.g. POSTGRES_14 or MYSQL_8_0"; };
            region = lib.mkOption { type = types.str; default = "europe-north1"; };
            tier = lib.mkOption { type = types.str; default = "db-f1-micro"; description = "Instance machine tier"; };
            deletionPolicy = lib.mkOption { type = types.str; default = "abandon"; description = "CNRM deletion policy (abandon or delete)"; };
          };
        }));
        default = [];
        description = "Cloud SQL instances (sql.cnrm.cloud.google.com/v1beta1 SQLInstance)";
      };
      databases = lib.mkOption {
        type = types.listOf (types.submodule ({ ... }: {
          options = {
            name = lib.mkOption { type = types.str; description = "Database name"; };
            instance = lib.mkOption { type = types.str; description = "Instance name reference"; };
            charset = lib.mkOption { type = types.nullOr types.str; default = null; };
            collation = lib.mkOption { type = types.nullOr types.str; default = null; };
          };
        }));
        default = [];
        description = "Cloud SQL databases (sql.cnrm.cloud.google.com/v1beta1 SQLDatabase)";
      };
      users = lib.mkOption {
        type = types.listOf (types.submodule ({ ... }: {
          options = {
            name = lib.mkOption { type = types.str; description = "User name"; };
            instance = lib.mkOption { type = types.str; description = "Instance name reference"; };
            passwordSecretName = lib.mkOption { type = types.nullOr types.str; default = null; description = "K8s Secret name containing password"; };
            passwordSecretKey = lib.mkOption { type = types.str; default = "password"; description = "Key in Secret containing password"; };
            type = lib.mkOption { type = types.str; default = "BUILT_IN"; };
            host = lib.mkOption { type = types.nullOr types.str; default = null; };
          };
        }));
        default = [];
        description = "Cloud SQL users (sql.cnrm.cloud.google.com/v1beta1 SQLUser)";
      };
  };
}
