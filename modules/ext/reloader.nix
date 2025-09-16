{ lib, ... }:
let types = lib.types; in
{
  options.app.reloader = {
    enable = lib.mkOption { type = types.bool; default = false; description = "Add reloader.stakater.com/search=true annotation on Deployment metadata."; };
  };
}

