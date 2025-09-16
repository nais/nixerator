{ lib, ... }:
let types = lib.types; in
{
  options.app.integrations = {
    wonderwall = lib.mkOption { type = types.submodule ({ ... }: { options = {
      enabled = lib.mkOption { type = types.bool; default = false; };
    }; }); default = { enabled = false; }; };
    azure = lib.mkOption { type = types.submodule ({ ... }: { options = {
      enabled = lib.mkOption { type = types.bool; default = false; };
      clientId = lib.mkOption { type = types.nullOr types.str; default = null; };
    }; }); default = { enabled = false; }; };
    texas = lib.mkOption { type = types.submodule ({ ... }: { options = {
      enabled = lib.mkOption { type = types.bool; default = false; };
    }; }); default = { enabled = false; }; };
    tokenx = lib.mkOption { type = types.submodule ({ ... }: { options = {
      enabled = lib.mkOption { type = types.bool; default = false; };
      clientId = lib.mkOption { type = types.nullOr types.str; default = null; };
    }; }); default = { enabled = false; }; };
    maskinporten = lib.mkOption { type = types.submodule ({ ... }: { options = {
      enabled = lib.mkOption { type = types.bool; default = false; };
      clientId = lib.mkOption { type = types.nullOr types.str; default = null; };
    }; }); default = { enabled = false; }; };
  };
}

