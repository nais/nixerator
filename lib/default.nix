{ lib }:

let
  toYaml = lib.generators.toYAML {};

  mkEnvList = envAttrs:
    lib.mapAttrsToList (name: value: { inherit name; value = toString value; }) envAttrs;

  ensureEnv = env:
    if lib.isAttrs env then mkEnvList env
    else if lib.isList env then env
    else [];
in

rec {
  inherit toYaml;

  mkDeployment = {
    name,
    namespace ? "default",
    image,
    replicas ? 1,
    env ? {},
    ports ? [{ name = "http"; containerPort = 8080; }],
    resources ? null,
    labels ? {},
    annotations ? {}
  }:
    {
      apiVersion = "apps/v1";
      kind = "Deployment";
      metadata = {
        inherit name namespace;
        labels = labels;
        annotations = annotations;
      };
      spec = {
        replicas = replicas;
        selector.matchLabels = { app = name; } // labels;
        template = {
          metadata.labels = { app = name; } // labels;
          spec.containers = [
            ({ inherit name image; ports = ports; }
              // (lib.optionalAttrs (env != {} && env != []) { env = ensureEnv env; })
              // (lib.optionalAttrs (resources != null) { inherit resources; })
            )
          ];
        };
      };
    };

  mkService = {
    name,
    namespace ? "default",
    port ? 80,
    targetPort ? 8080,
    type ? "ClusterIP",
    labels ? {},
    annotations ? {}
  }:
    {
      apiVersion = "v1";
      kind = "Service";
      metadata = {
        inherit name namespace;
        labels = labels;
        annotations = annotations;
      };
      spec = {
        type = type;
        selector = { app = name; } // labels;
        ports = [ { name = "http"; inherit port; targetPort = targetPort; } ];
      };
    };

  mkIngress = {
    name,
    namespace ? "default",
    host,
    servicePort ? 80,
    path ? "/",
    pathType ? "Prefix",
    tls ? null,
    labels ? {},
    annotations ? {}
  }:
    {
      apiVersion = "networking.k8s.io/v1";
      kind = "Ingress";
      metadata = {
        inherit name namespace;
        labels = labels;
        annotations = annotations;
      };
      spec = ({
        rules = [
          {
            inherit host;
            http.paths = [
              {
                inherit path pathType;
                backend.service = {
                  inherit name;
                  port.number = servicePort;
                };
              }
            ];
          }
        ];
      } // (lib.optionalAttrs (tls != null) { inherit tls; }));
    };

  mkHPA = {
    name,
    namespace ? "default",
    minReplicas ? 1,
    maxReplicas,
    targetCPUUtilizationPercentage ? 80
  }:
    {
      apiVersion = "autoscaling/v2";
      kind = "HorizontalPodAutoscaler";
      metadata = { inherit name namespace; };
      spec = {
        scaleTargetRef = {
          apiVersion = "apps/v1";
          kind = "Deployment";
          inherit name;
        };
        inherit minReplicas maxReplicas;
        metrics = [
          {
            type = "Resource";
            resource = {
              name = "cpu";
              target = {
                type = "Utilization";
                averageUtilization = targetCPUUtilizationPercentage;
              };
            };
          }
        ];
      };
    };

  mkSecret = {
    name,
    namespace ? "default",
    type ? "Opaque",
    data ? {},
    stringData ? {}
  }:
    ({
      apiVersion = "v1";
      kind = "Secret";
      metadata = { inherit name namespace; };
      type = type;
    }
    // (lib.optionalAttrs (data != {}) { inherit data; })
    // (lib.optionalAttrs (stringData != {}) { inherit stringData; }));

  renderManifests = manifests:
    lib.concatStringsSep "\n---\n" (map toYaml manifests);

  mkApp = {
    name,
    namespace ? "default",
    image,
    replicas ? 1,
    service ? { port = 80; targetPort = 8080; },
    ingress ? null,
    hpa ? null,
    env ? {},
    labels ? {},
    annotations ? {}
  }:
    let
      d = mkDeployment {
        inherit name namespace image replicas labels annotations;
        env = env;
        ports = [{ name = "http"; containerPort = service.targetPort; }];
      };
      s = mkService {
        inherit name namespace labels annotations;
        port = service.port;
        targetPort = service.targetPort;
      };
      i = if ingress == null then null else mkIngress ({
        inherit name namespace labels annotations;
        host = ingress.host;
        servicePort = service.port;
      } // (lib.optionalAttrs (ingress ? tls) { tls = ingress.tls; }));
      h = if hpa == null then null else mkHPA ({ inherit name namespace; } // hpa);
      all = [ d s ]
        ++ lib.optional (i != null) i
        ++ lib.optional (h != null) h;
    in {
      deployment = d;
      service = s;
      ingress = i;
      hpa = h;
      manifests = all;
      yaml = renderManifests all;
    };
}

