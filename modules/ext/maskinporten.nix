{ lib, ... }:
let types = lib.types; in
{
  options.app.maskinporten = {
    enable = lib.mkOption { type = types.bool; default = false; description = "Enable Maskinporten client"; };
    scopes = lib.mkOption {
      type = types.submodule ({ ... }: { options = {
        consumed = lib.mkOption { type = types.listOf types.str; default = []; };
        exposed = lib.mkOption { type = types.listOf types.str; default = []; };
      }; });
      default = { consumed = []; exposed = []; };
      description = "Maskinporten scopes (consumed/exposed)";
    };
  };
}

