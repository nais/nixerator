{ lib, ... }:
let types = lib.types; in
{
  options.app.texas = {
    enable = lib.mkOption { type = types.bool; default = false; description = "Enable Texas auth sidecar"; };
    image = lib.mkOption { type = types.str; default = "ghcr.io/nais/texas:latest"; description = "Texas image"; };
  };
}

