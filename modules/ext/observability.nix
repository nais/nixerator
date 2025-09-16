{ lib, ... }:
let types = lib.types; in
{
  options.app.observability = {
    defaultContainer = lib.mkOption { type = types.bool; default = false; description = "Annotate Pod with kubectl.kubernetes.io/default-container = app name."; };
    logformat = lib.mkOption { type = types.str; default = ""; description = "Set nais.io/logformat annotation if non-empty."; };
    logtransform = lib.mkOption { type = types.str; default = ""; description = "Set nais.io/logtransform annotation if non-empty."; };
  };
}
