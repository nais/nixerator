{ lib, ... }:
let types = lib.types; in
{
  options.app.podSecurity = {
    enable = lib.mkOption { type = types.bool; default = false; description = "Enable pod-level security defaults (FSGroup 1069, seccomp runtime/default, /tmp EmptyDir)."; };
    tmpVolumeName = lib.mkOption { type = types.str; default = "writable-tmp"; description = "Name of the EmptyDir volume mounted at /tmp when enabled."; };
  };
}

