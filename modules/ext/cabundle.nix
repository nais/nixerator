{ lib, ... }:
let types = lib.types; in
{
  options.app.caBundle = {
    enable = lib.mkOption { type = types.bool; default = false; description = "Mount NAV CA bundle configmaps and set envs"; };
  };
}

