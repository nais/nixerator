{ lib, ... }:
let types = lib.types; in
{
  options.app.webproxy = {
    enable = lib.mkOption { type = types.bool; default = false; description = "Enable HTTP(S) proxy env injection"; };
    httpProxy = lib.mkOption { type = types.str; default = "http://webproxy:8088"; };
    httpsProxy = lib.mkOption { type = types.nullOr types.str; default = null; description = "Defaults to httpProxy if null"; };
    noProxy = lib.mkOption { type = types.listOf types.str; default = []; description = "Values for NO_PROXY (comma-joined)"; };
  };
}

