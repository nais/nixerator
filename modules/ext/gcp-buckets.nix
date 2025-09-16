{ lib, ... }:
let types = lib.types; in
{
  options.app.gcp = {
    projectId = lib.mkOption { type = types.nullOr types.str; default = null; description = "Team project id (for CNRM resources and env)."; };
    googleProjectId = lib.mkOption { type = types.nullOr types.str; default = null; description = "Main Google project id (for IAM ServiceAccount in serviceaccounts ns)."; };
    buckets = lib.mkOption {
      type = types.listOf (types.submodule ({ ... }: { options = {
        name = lib.mkOption { type = types.str; description = "Bucket name (Kubernetes resource name)."; };
        location = lib.mkOption { type = types.str; default = "europe-north1"; description = "Bucket location."; };
        deletionPolicy = lib.mkOption { type = types.str; default = "abandon"; description = "cnrm.cloud.google.com/deletion-policy annotation."; };
      }; }));
      default = [];
      description = "List of GCP Storage buckets to create via Config Connector.";
    };
    iam = lib.mkOption {
      type = types.submodule ({ ... }: { options = {
        createServiceAccount = lib.mkOption { type = types.bool; default = false; description = "Create IAMServiceAccount in 'serviceaccounts' namespace (requires googleProjectId)."; };
        enableWorkloadIdentityBinding = lib.mkOption { type = types.bool; default = false; description = "Create IAMPolicy binding workloadIdentityUser on the service account."; };
        grantBucketViewer = lib.mkOption { type = types.bool; default = false; description = "Create IAMPolicyMember granting storage.objectViewer on the bucket to the service account."; };
      }; });
      default = { createServiceAccount = false; enableWorkloadIdentityBinding = false; grantBucketViewer = false; };
      description = "IAM helper toggles for buckets (parity with Naiserator CNRM helpers).";
    };
  };
}
