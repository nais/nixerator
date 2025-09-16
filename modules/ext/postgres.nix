{ lib, ... }:
let types = lib.types; in
{
  options.app.postgres = {
    enable = lib.mkOption { type = types.bool; default = false; description = "Enable Postgres operator cluster and inject env"; };
    cluster = lib.mkOption {
      type = types.submodule ({ ... }: { options = {
        name = lib.mkOption { type = types.str; default = ""; description = "Override cluster name (defaults to app name)"; };
        allowDeletion = lib.mkOption { type = types.bool; default = false; };
        highAvailability = lib.mkOption { type = types.bool; default = false; };
        majorVersion = lib.mkOption { type = types.str; default = "14"; };
        resources = lib.mkOption {
          type = types.submodule ({ ... }: { options = {
            cpu = lib.mkOption { type = types.str; default = "500m"; };
            memory = lib.mkOption { type = types.str; default = "512Mi"; };
            diskSize = lib.mkOption { type = types.str; default = "20Gi"; };
          }; });
          default = { cpu = "500m"; memory = "512Mi"; diskSize = "20Gi"; };
        };
        audit = lib.mkOption {
          type = types.submodule ({ ... }: { options = {
            enabled = lib.mkOption { type = types.bool; default = false; };
            statementClasses = lib.mkOption { type = types.listOf types.str; default = []; };
          }; });
          default = { enabled = false; statementClasses = []; };
        };
      }; });
      default = { };
    };
    database = lib.mkOption {
      type = types.submodule ({ ... }: { options = {
        collation = lib.mkOption { type = types.str; default = "en_US"; };
        extensions = lib.mkOption { type = types.listOf types.str; default = []; };
      }; });
      default = { collation = "en_US"; extensions = []; };
    };
    maintenanceWindow = lib.mkOption {
      type = types.nullOr (types.submodule ({ ... }: { options = {
        day = lib.mkOption { type = types.int; default = 0; description = "0=Everyday, 1=Mon..7=Sun"; };
        hour = lib.mkOption { type = types.nullOr types.int; default = null; };
      }; }));
      default = null;
    };
  };
}

