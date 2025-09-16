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

  mkPDB = {
    name,
    namespace ? "default",
    minAvailable ? null,
    maxUnavailable ? null,
    labels ? {},
    annotations ? {}
  }:
    {
      apiVersion = "policy/v1";
      kind = "PodDisruptionBudget";
      metadata = {
        inherit name namespace;
        labels = labels;
        annotations = annotations;
      };
      spec = ({ selector.matchLabels = { app = name; }; }
        // (lib.optionalAttrs (minAvailable != null) { inherit minAvailable; })
        // (lib.optionalAttrs (maxUnavailable != null) { inherit maxUnavailable; }));
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

  mkServiceAccount = {
    name,
    namespace ? "default",
    annotations ? {},
    labels ? {}
  }:
    {
      apiVersion = "v1";
      kind = "ServiceAccount";
      metadata = { inherit name namespace annotations labels; };
    };

  mkConfigMap = {
    name,
    namespace ? "default",
    data ? {},
    labels ? {},
    annotations ? {}
  }:
    {
      apiVersion = "v1";
      kind = "ConfigMap";
      metadata = { inherit name namespace labels annotations; };
      data = data;
    };

  mkNetworkPolicy = {
    name,
    namespace ? "default",
    policyTypes ? [ "Ingress" "Egress" ],
    podSelector ? { app = name; },
    ingress ? [],
    egress ? [],
    labels ? {},
    annotations ? {}
  }:
    {
      apiVersion = "networking.k8s.io/v1";
      kind = "NetworkPolicy";
      metadata = { inherit name namespace labels annotations; };
      spec = {
        podSelector.matchLabels = podSelector;
        policyTypes = policyTypes;
      } // (lib.optionalAttrs (ingress != []) { inherit ingress; })
        // (lib.optionalAttrs (egress != []) { inherit egress; });
    };

  mkServiceMonitor = {
    name,
    namespace ? "default",
    endpoints ? [ { port = "http"; path = "/metrics"; } ],
    selector ? { matchLabels = { app = name; }; },
    labels ? {},
    annotations ? {}
  }:
    {
      apiVersion = "monitoring.coreos.com/v1";
      kind = "ServiceMonitor";
      metadata = { inherit name namespace labels annotations; };
      spec = {
        inherit selector endpoints;
        namespaceSelector = {};
      };
    };

  renderManifests = manifests:
    lib.concatStringsSep "\n---\n" (map toYaml manifests);

  # Build resources from the evaluated module config under cfg.app
  fromAppConfig = cfg:
    let
      name = cfg.name;
      namespace = cfg.namespace;
      labels = cfg.labels or {};
      annotations = cfg.annotations or {};
      serviceCfg = cfg.service;
      ingressCfg = cfg.ingress;
      hpaCfg = cfg.hpa;
      secretsCfg = cfg.secrets or {};
      pdbCfg = cfg.pdb or { enable = false; };
      saCfg = cfg.serviceAccount or { enable = false; };
      cmCfg = cfg.configMaps or {};
      npCfg = cfg.networkPolicy or { enable = false; };
      promCfg = cfg.prometheus or { enable = false; };
      deployment = mkDeployment {
        inherit name namespace labels annotations;
        image = cfg.image;
        replicas = cfg.replicas;
        env = cfg.env;
        ports = [{ name = "http"; containerPort = serviceCfg.targetPort; }];
      };
      service = lib.optional serviceCfg.enable (mkService {
        inherit name namespace labels annotations;
        port = serviceCfg.port;
        targetPort = serviceCfg.targetPort;
        type = serviceCfg.type;
      });
      ingress = lib.optional (ingressCfg.enable && ingressCfg.host != null) (mkIngress ({
        inherit name namespace labels annotations;
        host = ingressCfg.host;
        path = ingressCfg.path;
        pathType = ingressCfg.pathType;
        servicePort = serviceCfg.port;
      } // (lib.optionalAttrs (ingressCfg.tls != null) { tls = ingressCfg.tls; })));
      hpa = lib.optional hpaCfg.enable (mkHPA {
        inherit name namespace;
        minReplicas = hpaCfg.minReplicas;
        maxReplicas = hpaCfg.maxReplicas;
        targetCPUUtilizationPercentage = hpaCfg.targetCPUUtilizationPercentage;
      });
      pdb = lib.optional (pdbCfg.enable or false) (mkPDB ({ inherit name namespace labels annotations; }
        // (lib.optionalAttrs (pdbCfg ? minAvailable) { minAvailable = pdbCfg.minAvailable; })
        // (lib.optionalAttrs (pdbCfg ? maxUnavailable) { maxUnavailable = pdbCfg.maxUnavailable; })));
      serviceAccount = lib.optional (saCfg.enable or false) (mkServiceAccount {
        inherit namespace;
        name = saCfg.name or name;
        annotations = saCfg.annotations or {};
        labels = labels;
      });
      configMaps = lib.mapAttrsToList (n: cm: mkConfigMap {
        name = n;
        inherit namespace;
        data = cm.data or {};
        labels = labels;
        annotations = annotations;
      }) cmCfg;
      networkPolicy = lib.optional (npCfg.enable or false) (mkNetworkPolicy ({ inherit name namespace labels annotations; }
        // (lib.optionalAttrs (npCfg ? policyTypes) { policyTypes = npCfg.policyTypes; })
        // (lib.optionalAttrs (npCfg ? podSelector) { podSelector = npCfg.podSelector; })
        // (lib.optionalAttrs (npCfg ? ingress) { ingress = npCfg.ingress; })
        // (lib.optionalAttrs (npCfg ? egress) { egress = npCfg.egress; })));
      serviceMonitor = lib.optional (promCfg.enable or false) (mkServiceMonitor ({ inherit name namespace labels annotations; }
        // (lib.optionalAttrs (promCfg ? endpoints) { endpoints = promCfg.endpoints; })
        // (lib.optionalAttrs (promCfg ? selector) { selector = promCfg.selector; })));
      secrets = lib.mapAttrsToList (n: s: mkSecret ({
        name = n;
        inherit namespace;
        type = s.type;
      } // (lib.optionalAttrs (s.data != {}) { data = s.data; })
        // (lib.optionalAttrs (s.stringData != {}) { stringData = s.stringData; }))) secretsCfg;
      res = [ deployment ]
        ++ service
        ++ ingress
        ++ hpa
        ++ pdb
        ++ serviceAccount
        ++ networkPolicy
        ++ serviceMonitor
        ++ secrets
        ++ configMaps;
    in {
      deployment = deployment;
      service = if service == [] then null else lib.head service;
      ingress = if ingress == [] then null else lib.head ingress;
      hpa = if hpa == [] then null else lib.head hpa;
      secrets = secrets;
      pdb = if pdb == [] then null else lib.head pdb;
      serviceAccount = if serviceAccount == [] then null else lib.head serviceAccount;
      networkPolicy = if networkPolicy == [] then null else lib.head networkPolicy;
      serviceMonitor = if serviceMonitor == [] then null else lib.head serviceMonitor;
      configMaps = configMaps;
      manifests = res;
      yaml = renderManifests res;
    };

  # Evaluate modules and return config + resources
  evalAppModules = { modules, specialArgs ? {} }:
    let
      eval = lib.evalModules { inherit modules; specialArgs = specialArgs // { inherit lib; }; };
      cfg = eval.config.app;
      built = fromAppConfig cfg;
    in {
      inherit cfg;
      inherit (eval) options;
      resources = built;
      yaml = built.yaml;
    };

  # Generate an Emacs Org document from an options tree (e.g., eval.options.app)
  orgDocsFromOptions = opts:
    let
      show = v:
        if v == null then "null"
        else if lib.isString v then v
        else builtins.toJSON v;
      flatten = prefix: as:
        lib.concatLists (lib.mapAttrsToList (n: v:
          let path = if prefix == "" then n else "${prefix}.${n}"; in
          if (lib.isAttrs v && (v ? _type && v._type == "option")) then [ { inherit path; opt = v; } ]
          else if lib.isAttrs v then flatten path v
          else []
        ) as);
      format = { path, opt }:
        let
          tname = if opt ? type && opt.type ? name then opt.type.name else "";
          def = if opt ? default then show opt.default else if opt ? defaultText then opt.defaultText else "-";
          ex = if opt ? example then show opt.example else null;
          desc = if opt ? description then opt.description else "";
          exLine = if ex == null then "" else "\n  - Example: " + ex;
        in "* ${path}\n  - Type: ${tname}\n  - Default: ${def}\n  - Description: ${desc}" + exLine;
      body = lib.concatStringsSep "\n\n" (map format (flatten "" opts));
    in "#+TITLE: Nixerator App Module Options\n\n" + body + "\n";

  # Convenience: generate docs from full eval (takes eval.options.app)
  orgDocsFromEval = eval: orgDocsFromOptions eval.options.app;

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
