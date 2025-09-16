{ lib, ... }:
let types = lib.types; in
{
  options.app.tokenx = {
    enable = lib.mkOption { type = types.bool; default = false; description = "Enable TokenX (Jwker) client"; };
  };
}

