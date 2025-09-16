{ lib, ... }:
let types = lib.types; in
{
  options.app.labelsDefaults = {
    addTeam = lib.mkOption { type = types.bool; default = false; description = "Add team label equal to namespace on all resources."; };
  };
}

