{ lib, ... }:
let types = lib.types; in
{
  options.app.defaultEnv = {
    enable = lib.mkOption { type = types.bool; default = false; description = "Inject NAIS_* and related default environment variables."; };
    clientIdOverride = lib.mkOption { type = types.nullOr types.str; default = null; description = "Override NAIS_CLIENT_ID value; defaults to '<namespace>:<name>'."; };
    googleTeamProjectId = lib.mkOption { type = types.nullOr types.str; default = null; description = "If set, adds GOOGLE_CLOUD_PROJECT and GCP_TEAM_PROJECT_ID env vars."; };
  };
}
