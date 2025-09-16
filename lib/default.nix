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
    command ? [],
    envFrom ? [],
    ports ? [{ name = "http"; containerPort = 8080; }],
    resources ? null,
    volumeMounts ? [],
    volumes ? [],
    livenessProbe ? null,
    readinessProbe ? null,
    startupProbe ? null,
    lifecycle ? null,
    serviceAccountName ? null,
    imagePullSecrets ? [],
    terminationGracePeriodSeconds ? null,
    strategy ? null,
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
      spec = ({
        replicas = replicas;
        selector.matchLabels = { app = name; } // labels;
        template = {
          metadata.labels = { app = name; } // labels;
          spec = ({
            containers = [
              ({ inherit name image; ports = ports; }
                // (lib.optionalAttrs (command != []) { inherit command; })
                // (lib.optionalAttrs (env != {} && env != []) { env = ensureEnv env; })
                // (lib.optionalAttrs (envFrom != []) { inherit envFrom; })
                // (lib.optionalAttrs (resources != null) { inherit resources; })
                // (lib.optionalAttrs (volumeMounts != []) { inherit volumeMounts; })
                // (lib.optionalAttrs (livenessProbe != null) { inherit livenessProbe; })
                // (lib.optionalAttrs (readinessProbe != null) { inherit readinessProbe; })
                // (lib.optionalAttrs (startupProbe != null) { inherit startupProbe; })
                // (lib.optionalAttrs (lifecycle != null) { inherit lifecycle; })
              )
            ];
          }
          // (lib.optionalAttrs (volumes != []) { inherit volumes; })
          // (lib.optionalAttrs (serviceAccountName != null) { inherit serviceAccountName; })
          // (lib.optionalAttrs (imagePullSecrets != []) { imagePullSecrets = map (n: { name = n; }) imagePullSecrets; })
          // (lib.optionalAttrs (terminationGracePeriodSeconds != null) { inherit terminationGracePeriodSeconds; }));
        };
      }
      // (lib.optionalAttrs (strategy != null) { inherit strategy; });
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

  # GKE FQDNNetworkPolicy (optional CRD)
  mkFQDNNetworkPolicy = {
    name,
    appName,
    namespace ? "default",
    rules ? [], # list of { host, ports = [int] }
    labels ? {},
    annotations ? {}
  }:
    let
      toRule = r: {
        to = [ { fqdns = [ r.host ]; } ];
        ports = map (p: { protocol = "TCP"; port = p; }) (r.ports or [ 443 ]);
      };
    in {
      apiVersion = "networking.gke.io/v1alpha3";
      kind = "FQDNNetworkPolicy";
      metadata = { inherit name namespace labels annotations; };
      spec = {
        podSelector.matchLabels = { app = appName; };
        egress = map toRule rules;
        policyTypes = [ "Egress" ];
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
      resourcesCfg = cfg.resources or { limits = {}; requests = {}; };
      serviceCfg = cfg.service;
      ingressCfg = cfg.ingress;
      hpaCfg = cfg.hpa;
      secretsCfg = cfg.secrets or {};
      pdbCfg = cfg.pdb or { enable = false; };
      saCfg = cfg.serviceAccount or { enable = false; };
      cmCfg = cfg.configMaps or {};
      npCfg = cfg.networkPolicy or { enable = false; };
      apCfg = cfg.accessPolicy or { enable = false; };
      fqdnCfg = cfg.fqdnPolicy or { enable = false; rules = []; };
      fqdnFromAP = ((apCfg.outbound or {}).allowedFQDNs or []);
      fqdnRulesCombined = (fqdnCfg.rules or []) ++ fqdnFromAP;
      promCfg = cfg.prometheus or { enable = false; };
      imagePullSecrets = cfg.imagePullSecrets or [];
      # Convert probes to Kubernetes shape if enabled (non-empty path)
      mkProbe = probeCfg: let
        path = probeCfg.path or "";
        port = if (probeCfg.port or null) != null then probeCfg.port else serviceCfg.targetPort;
      in if path == "" then null else {
        httpGet = { inherit path; port = port; };
        initialDelaySeconds = probeCfg.initialDelaySeconds or 0;
        periodSeconds = probeCfg.periodSeconds or 10;
        timeoutSeconds = probeCfg.timeoutSeconds or 1;
        failureThreshold = probeCfg.failureThreshold or 3;
      };
      livenessProbe = mkProbe (cfg.probes.liveness or { path = ""; });
      readinessProbe = mkProbe (cfg.probes.readiness or { path = ""; });
      startupProbe = mkProbe (cfg.probes.startup or { path = ""; });
      # envFrom mapping
      envFrom = map (ef:
        if (ef.configMap or "") != "" then { configMapRef = { name = ef.configMap; }; }
        else if (ef.secret or "") != "" then { secretRef = { name = ef.secret; }; }
        else {}
      ) (cfg.envFrom or []);
      # filesFrom -> volumes + mounts (ConfigMap, Secret, PVC, EmptyDir)
      filesFromList = cfg.filesFrom or [];
      sanitize = s: let
        s1 = lib.replaceStrings ["/" ":" " "] ["-" "-" "-"] s;
        s2 = lib.replaceStrings ["_" ".." "--"] ["-" "." "-"] s1;
      in lib.removePrefix "-" (lib.removeSuffix "-" s2);
      filesVolumes = lib.concatMap (f:
        let cm = f.configMap or ""; sc = f.secret or ""; pvc = f.persistentVolumeClaim or ""; ed = f.emptyDir or null;
            name = if cm != "" then cm else if sc != "" then sc else if pvc != "" then pvc else if ed != null then "emptydir-" + sanitize f.mountPath else "";
        in if cm != "" then [ { inherit name; configMap = { name = cm; }; } ]
           else if sc != "" then [ { inherit name; secret = { secretName = sc; }; } ]
           else if pvc != "" then [ { inherit name; persistentVolumeClaim = { claimName = pvc; }; } ]
           else if ed != null then [ { inherit name; emptyDir = (if (ed.medium or null) == null then {} else { medium = ed.medium; }); } ]
           else []
      ) filesFromList;
      filesMounts = lib.concatMap (f:
        let cm = f.configMap or ""; sc = f.secret or ""; pvc = f.persistentVolumeClaim or ""; ed = f.emptyDir or null;
            name = if cm != "" then cm else if sc != "" then sc else if pvc != "" then pvc else if ed != null then "emptydir-" + sanitize f.mountPath else "";
            roDefault = if pvc != "" || ed != null then false else true;
            ro = if f ? readOnly && f.readOnly != null then f.readOnly else roDefault;
        in if name != "" then [ { inherit name; mountPath = f.mountPath; readOnly = ro; } ] else []
      ) filesFromList;
      # lifecycle preStop mapping
      preStopCfg = cfg.preStop or null;
      lifecycle = if preStopCfg == null then null else (
        if (preStopCfg.exec or null) != null && (preStopCfg.exec.command or []) != [] then {
          preStop = { exec = { command = preStopCfg.exec.command; }; };
        } else if (preStopCfg.http or null) != null && (preStopCfg.http.path or "") != "" then {
          preStop = { httpGet = { path = preStopCfg.http.path; port = (preStopCfg.http.port or serviceCfg.targetPort); }; };
        } else null
      );
      # strategy mapping
      strategy = let st = cfg.strategy or { type = "RollingUpdate"; }; in
        if (st.type or "RollingUpdate") == "Recreate" then { type = "Recreate"; }
        else ({ type = "RollingUpdate"; }
          // (lib.optionalAttrs ((st.rollingUpdate or null) != null && ((st.rollingUpdate.maxSurge or null) != null || (st.rollingUpdate.maxUnavailable or null) != null)) {
            rollingUpdate = {}
              // (lib.optionalAttrs ((st.rollingUpdate.maxSurge or null) != null) { maxSurge = st.rollingUpdate.maxSurge; })
              // (lib.optionalAttrs ((st.rollingUpdate.maxUnavailable or null) != null) { maxUnavailable = st.rollingUpdate.maxUnavailable; });
          }));
      deployment = mkDeployment {
        inherit name namespace labels annotations;
        image = cfg.image;
        replicas = cfg.replicas;
        env = cfg.env;
        command = cfg.command or [];
        ports = [{ name = "http"; containerPort = serviceCfg.targetPort; }];
        envFrom = lib.filter (x: x != {}) envFrom;
        resources = (if (resourcesCfg.limits or {}) == {} && (resourcesCfg.requests or {}) == {} then null else resourcesCfg);
        volumeMounts = filesMounts;
        volumes = filesVolumes;
        livenessProbe = livenessProbe;
        readinessProbe = readinessProbe;
        startupProbe = startupProbe;
        lifecycle = lifecycle;
        serviceAccountName = if (saCfg.enable or false) then (saCfg.name or name) else null;
        imagePullSecrets = imagePullSecrets;
        terminationGracePeriodSeconds = cfg.terminationGracePeriodSeconds or null;
        strategy = strategy;
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
      # accessPolicy -> a generated NetworkPolicy named "${name}-access"
      accessNetworkPolicy =
        let
          # Utility: build a namespaceSelector for a given ns name
          nsSel = ns: { namespaceSelector = { matchLabels = { "kubernetes.io/metadata.name" = ns; }; }; };
          # Optional ports block
          mkPorts = ports: if ports == [] then [] else map (p: { port = p; }) ports;
          inboundRules =
            let
              sameNs = if (apCfg.inbound or {}).allowSameNamespace or false
                then [ { from = [ nsSel namespace ]; ports = mkPorts ((apCfg.inbound or {}).ports or []); } ] else [];
              nsRules = lib.concatMap (ns: [ { from = [ nsSel ns ]; ports = mkPorts ((apCfg.inbound or {}).ports or []); } ]) (((apCfg.inbound or {}).allowedNamespaces) or []);
              appRules = lib.concatMap (appName: [ {
                from = [ { podSelector = { matchLabels = { app = appName; }; }; } ];
                ports = mkPorts ((apCfg.inbound or {}).ports or []);
              } ]) (((apCfg.inbound or {}).allowedApps) or []);
            in sameNs ++ nsRules ++ appRules;
          egressRules =
            let
              allowAll = (apCfg.outbound or {}).allowAll or true;
            in if allowAll then [] else (
              let
                nsPeers = map (ns: nsSel ns) (((apCfg.outbound or {}).allowedNamespaces) or []);
                cidrPeers = map (cidr: { ipBlock = { inherit cidr; }; }) (((apCfg.outbound or {}).allowedCIDRs) or []);
                ports = mkPorts (((apCfg.outbound or {}).allowedPorts) or []);
                dnsRule = if ((apCfg.outbound or {}).allowDNS or false)
                  then [ { ports = [ { protocol = "UDP"; port = 53; } ]; } ] else [];
                baseRule = if (nsPeers ++ cidrPeers) == [] && ports == [] then [] else [ ({ to = nsPeers ++ cidrPeers; } // (lib.optionalAttrs (ports != []) { inherit ports; })) ];
              in baseRule ++ dnsRule
            );
          policyTypes = []
            ++ (if inboundRules != [] then [ "Ingress" ] else [])
            ++ (if egressRules != [] then [ "Egress" ] else []);
        in lib.optional (apCfg.enable or false && (inboundRules != [] || egressRules != []))
          (mkNetworkPolicy {
            name = "${name}-access";
            inherit namespace labels annotations;
            policyTypes = policyTypes;
            ingress = inboundRules;
            egress = egressRules;
          });
      serviceMonitor = lib.optional (promCfg.enable or false) (mkServiceMonitor ({ inherit name namespace labels annotations; }
        // (lib.optionalAttrs (promCfg ? endpoints) { endpoints = promCfg.endpoints; })
        // (lib.optionalAttrs (promCfg ? selector) { selector = promCfg.selector; })));
      fqdnPolicy = lib.optional ((fqdnCfg.enable or false) || ((apCfg.enable or false) && fqdnFromAP != [])) (mkFQDNNetworkPolicy {
        name = "${name}-fqdn";
        appName = name;
        inherit namespace labels annotations;
        rules = fqdnRulesCombined;
      });
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
        ++ accessNetworkPolicy
        ++ fqdnPolicy
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
      accessNetworkPolicy = if accessNetworkPolicy == [] then null else lib.head accessNetworkPolicy;
      fqdnNetworkPolicy = if fqdnPolicy == [] then null else lib.head fqdnPolicy;
      serviceMonitor = if serviceMonitor == [] then null else lib.head serviceMonitor;
      configMaps = configMaps;
      manifests = res;
      yaml = renderManifests res;
    };

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

  # Fancy Org docs with TOC, grouped tables, and usage snippet
  orgDocsFancyFromOptions = opts:
    let
      show = v:
        if v == null then "null"
        else if lib.isString v then v
        else builtins.toJSON v;
      esc = s: lib.replaceStrings ["\n" "|"] [" " "\\|"] (toString s);
      flatten = prefix: as:
        lib.concatLists (lib.mapAttrsToList (n: v:
          let path = if prefix == "" then n else "${prefix}.${n}"; in
          if (lib.isAttrs v && (v ? _type && v._type == "option")) then [ { inherit path; opt = v; } ]
          else if lib.isAttrs v then flatten path v
          else []
        ) as);
      items = flatten "" opts;
      groupKey = item:
        let parts = lib.splitString "." item.path;
        in if builtins.length parts <= 1 then "core" else builtins.head parts;
      groups = lib.groupBy groupKey items;
      cap = s: let len = lib.stringLength s; in
        (lib.toUpper (lib.substring 0 1 s)) + (if len > 1 then lib.substring 1 (len - 1) s else "");
      relPath = item:
        let parts = lib.splitString "." item.path; in
        if builtins.length parts <= 1 then item.path else lib.concatStringsSep "." (lib.tail parts);
      tname = opt: if opt ? type && opt.type ? name then opt.type.name else "";
      defv = opt:
        if opt ? default then show opt.default
        else if opt ? defaultText then opt.defaultText
        else "-";
      exv = opt: if opt ? example then show opt.example else "";
      row = item: "| " + esc (relPath item)
        + " | " + esc (tname item.opt)
        + " | " + esc (defv item.opt)
        + " | " + esc (if item.opt ? description then item.opt.description else "")
        + " | " + (let e = exv item.opt; in if e == "" then "" else esc e)
        + " |";
      section = name: is:
        let
          header = "** " + cap name + "\n| Option | Type | Default | Description | Example |\n|-" + (lib.concatStringsSep "-" (lib.replicate 4 "|-") ) + "|\n";
          rows = lib.concatStringsSep "\n" (map row is);
        in header + rows + "\n";
      intro = ''#+TITLE: Nixerator Application Module Options
#+OPTIONS: toc:2 num:t
#+TOC: headlines 2

This document lists the available options for the Nixerator application module,
grouped by area. Values show types, defaults, and examples when available.

* Usage
#+BEGIN_SRC nix
nixerator.lib.simple.yamlFromApp {
  name = "myapp";
  namespace = "default";
  image = "repo/image:tag";
  replicas = 2;
  service.enable = true;
  ingress.enable = true; ingress.host = "myapp.example.com";
  hpa.enable = true; hpa.maxReplicas = 4;
  pdb.enable = true; pdb.minAvailable = 1;
  serviceAccount.enable = true;
}
#+END_SRC

* Options
'';
      body = lib.concatStringsSep "\n" (
        map (name: section name groups.${name}) (lib.attrNames groups)
      );
    in intro + body;

  # Fancy docs from full eval (takes eval.options.app)
  orgDocsFancyFromEval = eval: orgDocsFancyFromOptions eval.options.app;

  # Narrative (no tables) Org docs with TOC and usage
  orgDocsNoTableFromOptions = opts:
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
      items = flatten "" opts;
      groupKey = item:
        let parts = lib.splitString "." item.path;
        in if builtins.length parts <= 1 then "core" else builtins.head parts;
      groups = lib.groupBy groupKey items;
      cap = s: let len = lib.stringLength s; in
        (lib.toUpper (lib.substring 0 1 s)) + (if len > 1 then lib.substring 1 (len - 1) s else "");
      relPath = item:
        let parts = lib.splitString "." item.path; in
        if builtins.length parts <= 1 then item.path else lib.concatStringsSep "." (lib.tail parts);
      tname = opt: if opt ? type && opt.type ? name then opt.type.name else "";
      defv = opt:
        if opt ? default then show opt.default
        else if opt ? defaultText then opt.defaultText
        else "-";
      exv = opt: if opt ? example then show opt.example else null;
      sectionItem = item:
        let
          desc = if item.opt ? description then item.opt.description else "";
          ex = exv item.opt;
          exampleLine = if ex == null then "" else "\n  - Example: " + ex;
        in "*** " + relPath item
          + "\n  - Type: " + (tname item.opt)
          + "\n  - Default: " + (defv item.opt)
          + "\n  - Description: " + desc
          + exampleLine + "\n";
      sectionGroup = name: is:
        let body = lib.concatStringsSep "\n" (map sectionItem is); in
        "** " + cap name + "\n\n" + body;
      intro = ''#+TITLE: Nixerator Application Module Options
#+OPTIONS: toc:2 num:t
#+TOC: headlines 2

This document lists the available options for the Nixerator application module,
grouped by area. Each option shows its type, default, and description.

* Usage
#+BEGIN_SRC nix
nixerator.lib.simple.yamlFromApp {
  name = "myapp";
  namespace = "default";
  image = "repo/image:tag";
  replicas = 2;
  service.enable = true;
  ingress.enable = true; ingress.host = "myapp.example.com";
  hpa.enable = true; hpa.maxReplicas = 4;
  pdb.enable = true; pdb.minAvailable = 1;
  serviceAccount.enable = true;
}
#+END_SRC

* Options
'';
      body = lib.concatStringsSep "\n" (
        map (name: sectionGroup name groups.${name}) (lib.attrNames groups)
      );
    in intro + body;

  orgDocsNoTableFromEval = eval: orgDocsNoTableFromOptions eval.options.app;

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
