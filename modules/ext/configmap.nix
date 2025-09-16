{ lib, ... }:
let types = lib.types; in
{
  options.app.configMaps = lib.mkOption {
    type = types.attrsOf (types.submodule ({ ... }: {
      options = {
        data = lib.mkOption {
          type = types.attrsOf types.str;
          default = {};
          description = "Key-value data entries for the ConfigMap.";
        };
      };
    }));
    default = {};
    description = "ConfigMaps to create, keyed by name.";
    example = {
      app-config = { data = { LOG_LEVEL = "info"; FEATURE_X = "true"; }; };
    };
  };
}

