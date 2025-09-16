{ lib, ... }:
let types = lib.types; in
{
  options.app.serviceAccount = {
    enable = lib.mkOption {
      type = types.bool;
      default = false;
      description = "Create a ServiceAccount for the app.";
    };
    name = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "ServiceAccount name (defaults to app name if null).";
    };
    annotations = lib.mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Annotations for the ServiceAccount (e.g., IAM roles).";
    };
  };
}

