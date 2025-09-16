{ lib, ... }:
let types = lib.types; in
{
  options.app.leaderElection = {
    enable = lib.mkOption { type = types.bool; default = false; description = "Enable leader election flag/label"; };
  };
}

