{ lib, ... }:
let types = lib.types; in
{
  options.app.ttl = {
    enable = lib.mkOption { type = types.bool; default = false; description = "Enable euthanaisa TTL annotations/labels."; };
    duration = lib.mkOption { type = types.nullOr types.str; default = null; description = "Duration string (e.g., 24h). When set, writes euthanaisa.nais.io/ttl annotation."; };
    killAfter = lib.mkOption { type = types.nullOr types.str; default = null; description = "Absolute RFC3339 timestamp for kill-after; if set, writes euthanaisa.nais.io/kill-after annotation."; };
  };
}

