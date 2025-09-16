{ lib, ... }:
let types = lib.types; in
{
  options.app.pdb = {
    enable = lib.mkOption {
      type = types.bool;
      default = false;
      description = "Enable PodDisruptionBudget for the app.";
    };
    minAvailable = lib.mkOption {
      type = types.nullOr (types.oneOf [ types.int types.str ]);
      default = null;
      description = "Minimum pods available (int or percentage string).";
    };
    maxUnavailable = lib.mkOption {
      type = types.nullOr (types.oneOf [ types.int types.str ]);
      default = null;
      description = "Maximum pods unavailable (int or percentage string).";
    };
  };
}

