{ lib, ... }:
let types = lib.types; in
{
  options.app.securelogs = {
    enable = lib.mkOption { type = types.bool; default = false; description = "Enable secure logs sidecar, volumes, and mounts."; };
    image = lib.mkOption { type = types.str; default = "fluentbit:latest"; description = "Fluent Bit image for secure logs sidecar (k8s operator-configured in NAIS)."; };
    sizeLimit = lib.mkOption { type = types.str; default = "128M"; description = "Size limit for secure-logs EmptyDir volume."; };
  };
}

