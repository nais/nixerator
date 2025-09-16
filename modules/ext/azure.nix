{ lib, ... }:
let types = lib.types; in
{
  options.app.azure = {
    application = lib.mkOption {
      type = types.submodule ({ ... }: { options = {
        enabled = lib.mkOption { type = types.bool; default = false; };
        tenant = lib.mkOption { type = types.nullOr types.str; default = null; };
        claims = lib.mkOption { type = types.attrsOf types.anything; default = {}; };
        singlePageApplication = lib.mkOption { type = types.bool; default = false; };
        allowAllUsers = lib.mkOption { type = types.bool; default = false; };
        replyURLs = lib.mkOption { type = types.listOf types.str; default = []; description = "Explicit reply URLs; defaults to ingress host + /oauth2/callback"; };
      }; });
      default = { enabled = false; };
    };
    sidecar = lib.mkOption {
      type = types.submodule ({ ... }: { options = {
        enabled = lib.mkOption { type = types.bool; default = false; };
        autoLogin = lib.mkOption { type = types.bool; default = false; };
        autoLoginIgnorePaths = lib.mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Paths ignored by auto-login, comma-joined to WONDERWALL_AUTO_LOGIN_IGNORE_PATHS";
        };
        image = lib.mkOption { type = types.str; default = "ghcr.io/nais/wonderwall:latest"; };
      }; });
      default = { enabled = false; };
    };
  };
}

