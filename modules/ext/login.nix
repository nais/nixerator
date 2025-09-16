{ lib, ... }:
let types = lib.types; in
{
  options.app.login = {
    enable = lib.mkOption { type = types.bool; default = false; description = "Enable login proxy (Wonderwall)"; };
    provider = lib.mkOption { type = types.str; default = "idporten"; description = "OpenID provider for login proxy (e.g., idporten)"; };
    enforce = lib.mkOption {
      type = types.submodule ({ ... }: { options = {
        enabled = lib.mkOption { type = types.bool; default = false; };
        excludePaths = lib.mkOption { type = types.listOf types.str; default = []; };
      }; });
      default = { enabled = false; excludePaths = []; };
    };
  };
}

