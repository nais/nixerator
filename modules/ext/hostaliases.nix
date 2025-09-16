{ lib, ... }:
let types = lib.types; in
{
  options.app.hostAliases = lib.mkOption {
    type = types.listOf (types.submodule ({ ... }: {
      options = {
        host = lib.mkOption { type = types.str; description = "Hostname to alias (added to Pod hostAliases)."; };
        ip = lib.mkOption { type = types.str; description = "IP address for the alias."; };
      };
    }));
    default = [];
    description = "List of host aliases (host, ip), applied to Pod spec.hostAliases.";
    example = [ { host = "db.internal"; ip = "10.0.0.10"; } ];
  };
}

