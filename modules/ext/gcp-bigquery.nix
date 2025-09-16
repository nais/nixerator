{ lib, ... }:
let types = lib.types; in
{
  options.app.gcp = {
    bigQueryDatasets = lib.mkOption {
      type = types.listOf (types.submodule ({ ... }: { options = {
        name = lib.mkOption { type = types.str; description = "BigQuery dataset name (will be normalized to lowercase underscores)."; };
        description = lib.mkOption { type = types.nullOr types.str; default = null; description = "Dataset description."; };
        permission = lib.mkOption { type = types.enum [ "READ" "READWRITE" ]; default = "READ"; description = "Permission for app service account (READ=READER, READWRITE=WRITER)."; };
        cascadingDelete = lib.mkOption { type = types.bool; default = false; description = "If true, annotate dataset with delete-contents-on-destroy=true."; };
      }; }));
      default = [];
      description = "Google BigQuery datasets to create (google.nais.io/v1 BigQueryDataset).";
    };
  };
}

