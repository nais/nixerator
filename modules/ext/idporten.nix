{ lib, ... }:
let types = lib.types; in
{
  options.app.idporten = {
    enable = lib.mkOption { type = types.bool; default = false; description = "Enable IDPorten client + sidecar"; };
    sidecar = lib.mkOption {
      type = types.submodule ({ ... }: { options = {
        enabled = lib.mkOption { type = types.bool; default = false; };
        autoLogin = lib.mkOption { type = types.bool; default = false; };
        autoLoginIgnorePaths = lib.mkOption { type = types.listOf types.str; default = []; };
        level = lib.mkOption { type = types.nullOr types.str; default = null; description = "ACR level (values like Level4/Level3)"; };
        locale = lib.mkOption { type = types.nullOr types.str; default = null; };
      }; });
      default = { enabled = false; };
    };
  };
}

