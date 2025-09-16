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
    initContainers ? [],
    livenessProbe ? null,
    readinessProbe ? null,
    startupProbe ? null,
    lifecycle ? null,
    podAnnotations ? {},
    podSecurityContext ? null,
    serviceAccountName ? null,
    imagePullSecrets ? [],
    tolerations ? [],
    affinity ? null,
    hostAliases ? [],
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
          metadata = {
            labels = { app = name; } // labels;
          } // (lib.optionalAttrs (podAnnotations != {}) { annotations = podAnnotations; });
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
          // (lib.optionalAttrs (initContainers != []) { inherit initContainers; })
          // (lib.optionalAttrs (volumes != []) { inherit volumes; })
          // (lib.optionalAttrs (serviceAccountName != null) { inherit serviceAccountName; })
          // (lib.optionalAttrs (imagePullSecrets != []) { imagePullSecrets = map (n: { name = n; }) imagePullSecrets; })
          // (lib.optionalAttrs (podSecurityContext != null) { securityContext = podSecurityContext; })
          // (lib.optionalAttrs (tolerations != []) { inherit tolerations; })
          // (lib.optionalAttrs (hostAliases != []) { inherit hostAliases; })
          // (lib.optionalAttrs (affinity != null) { inherit affinity; })
          // (lib.optionalAttrs (terminationGracePeriodSeconds != null) { inherit terminationGracePeriodSeconds; }));
        };
      } // (lib.optionalAttrs (strategy != null) { inherit strategy; }));
    };

  mkService = {
    name,
    namespace ? "default",
    port ? 80,
    targetPort ? 8080,
    portName ? "http",
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
        ports = [ { name = portName; inherit port; targetPort = targetPort; } ];
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
    targetCPUUtilizationPercentage ? null,
    kafka ? null
  }:
    let
      cpuMetric = if targetCPUUtilizationPercentage == null then [] else [
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
      kafkaMetric = if kafka == null then [] else [
        {
          type = "External";
          external = {
            metric = {
              name = "kafka_consumergroup_group_lag";
              selector = {
                matchLabels = {
                  topic = kafka.topic;
                  group = kafka.consumerGroup;
                };
              };
            };
            target = {
              type = "AverageValue";
              averageValue = toString kafka.threshold;
            };
          };
        }
      ];
      metrics = cpuMetric ++ kafkaMetric;
    in {
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
        metrics = metrics;
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

  # GCP Config Connector (CNRM) resources (minimal)
  mkStorageBucket = {
    name,
    namespace,
    projectId,
    location ? "europe-north1",
    deletionPolicy ? "abandon",
    labels ? {},
    annotations ? {}
  }:
    {
      apiVersion = "storage.cnrm.cloud.google.com/v1beta1";
      kind = "StorageBucket";
      metadata = {
        inherit name namespace;
        labels = labels;
        annotations = annotations // {
          "cnrm.cloud.google.com/project-id" = projectId;
          "cnrm.cloud.google.com/deletion-policy" = deletionPolicy;
        };
      };
      spec = {
        inherit location;
        publicAccessPrevention = "inherited";
      };
    };

  mkIAMServiceAccount = {
    name,
    projectId,
    displayName,
    namespace ? "serviceaccounts",
    annotations ? {}
  }:
    {
      apiVersion = "iam.cnrm.cloud.google.com/v1beta1";
      kind = "IAMServiceAccount";
      metadata = {
        inherit name namespace;
        annotations = annotations // { "cnrm.cloud.google.com/project-id" = projectId; };
      };
      spec.displayName = displayName;
    };

  mkIAMPolicy = {
    name,
    namespace ? "serviceaccounts",
    projectId,
    memberNamespace,
    memberName
  }:
    {
      apiVersion = "iam.cnrm.cloud.google.com/v1beta1";
      kind = "IAMPolicy";
      metadata = {
        inherit name namespace;
        annotations."cnrm.cloud.google.com/project-id" = projectId;
      };
      spec = {
        bindings = [ {
          role = "roles/iam.workloadIdentityUser";
          members = [ "serviceAccount:${projectId}.svc.id.goog[${memberNamespace}/${memberName}]" ];
        } ];
        resourceRef = { apiVersion = "iam.cnrm.cloud.google.com/v1beta1"; kind = "IAMServiceAccount"; inherit name; };
      };
    };

  mkIAMPolicyMember = {
    name,
    namespace,
    teamProjectId,
    googleProjectId,
    bucketName
  }:
    {
      apiVersion = "iam.cnrm.cloud.google.com/v1beta1";
      kind = "IAMPolicyMember";
      metadata = {
        inherit name namespace;
        annotations."cnrm.cloud.google.com/project-id" = teamProjectId;
      };
      spec = {
        member = "serviceAccount:${name}@${googleProjectId}.iam.gserviceaccount.com";
        role = "roles/storage.objectViewer";
        resourceRef = { apiVersion = "storage.cnrm.cloud.google.com/v1beta1"; kind = "StorageBucket"; name = bucketName; };
      };
    };

  mkPodMonitor = {
    name,
    namespace ? "default",
    path ? "/metrics",
    port ? "http",
    labels ? {},
    annotations ? {}
  }:
    {
      apiVersion = "monitoring.coreos.com/v1";
      kind = "PodMonitor";
      metadata = { inherit name namespace labels annotations; };
      spec = {
        jobLabel = "app.kubernetes.io/name";
        podTargetLabels = [ "app" "team" ];
        selector.matchLabels = { app = name; };
        podMetricsEndpoints = [ ({ inherit port path; honorLabels = false; }) ];
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

  # AivenApplication (aiven.nais.io/v1)
  mkAivenApplication = {
    name,
    namespace ? "default",
    labels ? {},
    annotations ? {},
    spec ? {}
  }:
    {
      apiVersion = "aiven.nais.io/v1";
      kind = "AivenApplication";
      metadata = { inherit name namespace labels annotations; };
      spec = spec;
    };

  # Aiven Valkey (aiven.io/v1alpha1)
  mkAivenValkey = {
    name,
    namespace ? "default",
    project,
    plan ? "startup-4",
    appTag ? null,
    labels ? {},
    annotations ? {},
  }:
    {
      apiVersion = "aiven.io/v1alpha1";
      kind = "Valkey";
      metadata = { inherit name namespace labels annotations; };
      spec = {
        project = project;
        plan = plan;
        tags = (lib.optionalAttrs (appTag != null) { app = appTag; });
      };
    };

  # Kafka Stream (kafka.nais.io/v1)
  mkKafkaStream = {
    name,
    namespace ? "default",
    pool,
    labels ? {},
    annotations ? {}
  }:
    {
      apiVersion = "kafka.nais.io/v1";
      kind = "Stream";
      metadata = { inherit name namespace labels annotations; };
      spec = { inherit pool; };
    };

  renderManifests = manifests:
    lib.concatStringsSep "\n---\n" (map toYaml manifests);

  # Build resources from the evaluated module config under cfg.app
  fromAppConfig = cfg:
    let
      name = cfg.name;
      namespace = cfg.namespace;
      labels = cfg.labels or {};
      labelsDefaults = (cfg.labelsDefaults or {});
      labelsWithTeam = if (labelsDefaults.addTeam or false) then (labels // { team = namespace; }) else labels;
      annotations = cfg.annotations or {};
      resourcesCfg = cfg.resources or { limits = {}; requests = {}; };
      serviceCfg = cfg.service;
      ingressCfg = cfg.ingress;
      hpaCfg = cfg.hpa;
      secretsCfg = cfg.secrets or {};
      pdbCfg = cfg.pdb or { enable = false; };
      saCfg = cfg.serviceAccount or { enable = false; };
      cmCfg = cfg.configMaps or {};
      feCfg = cfg.frontend or {};
      slCfg = cfg.securelogs or { enable = false; };
      gcpCfg = cfg.gcp or {};
      vaultCfg = cfg.vault or { enable = false; };
      npCfg = cfg.networkPolicy or { enable = false; };
      apCfg = cfg.accessPolicy or { enable = false; };
      fqdnCfg = cfg.fqdnPolicy or { enable = false; rules = []; };
      outboundForFqdn = apCfg.outbound or {};
      fqdnFromAP = outboundForFqdn.allowedFQDNs or [];
      fqdnRulesCombined = (fqdnCfg.rules or []) ++ fqdnFromAP;
      promCfg = cfg.prometheus or { enable = false; };
      schedCfg = cfg.scheduling or {};
      imagePullSecrets = cfg.imagePullSecrets or [];
      # Aiven integration
      aivenCfg = cfg.aiven or { enable = false; };
      aivenEnabled = aivenCfg.enable or false;
      aivenRange = aivenCfg.rangeCIDR or null;
      aivenKafka = aivenCfg.kafka or null;
      aivenOpenSearch = aivenCfg.openSearch or null;
      aivenValkey = aivenCfg.valkey or [];
      aivenProject = aivenCfg.project or null;
      aivenManageInstances = aivenCfg.manageInstances or false;
      # Scheduling: tolerations and anti-affinity
      tolerations = schedCfg.tolerations or [];
      affinity = let aa = schedCfg.antiAffinity or { enable = false; }; in
        if (aa.enable or false) then (
          if (aa.type or "required") == "required" then {
            podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution = [
              { labelSelector.matchLabels = { app = name; }; topologyKey = (aa.topologyKey or "kubernetes.io/hostname"); }
            ];
          } else {
            podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution = [
              { weight = 100; podAffinityTerm = { labelSelector.matchLabels = { app = name; }; topologyKey = (aa.topologyKey or "kubernetes.io/hostname"); }; }
            ];
          }
        ) else null;
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
      # Deployment metadata annotations augments (reloader, ttl)
      reloaderAnn = if ((cfg.reloader or { enable = false; }).enable or false) then { "reloader.stakater.com/search" = "true"; } else {};
      ttlCfg = cfg.ttl or { enable = false; };
      ttlAnn = if (ttlCfg.enable or false) then (
        if (ttlCfg.killAfter or null) != null then { "euthanaisa.nais.io/kill-after" = ttlCfg.killAfter; }
        else if (ttlCfg.duration or null) != null then { "euthanaisa.nais.io/ttl" = ttlCfg.duration; }
        else {}
      ) else {};
      ttlLabel = if (ttlCfg.enable or false) then { "euthanaisa.nais.io/enabled" = "true"; } else {};

      # Pod annotations (observability)
      obs = cfg.observability or {};
      podAnn = {}
        // (lib.optionalAttrs (obs.defaultContainer or false) { "kubectl.kubernetes.io/default-container" = name; })
        // (lib.optionalAttrs ((obs.logformat or "") != "") { "nais.io/logformat" = obs.logformat; })
        // (lib.optionalAttrs ((obs.logtransform or "") != "") { "nais.io/logtransform" = obs.logtransform; })
        // (let ai = obs.autoInstrumentation or { enabled = false; }; in
             lib.optionalAttrs (ai.enabled or false && (ai.appConfig or null) != null) (
               {
                 ${"instrumentation.opentelemetry.io/inject-" + (ai.runtime or "java")} = ai.appConfig;
                 "instrumentation.opentelemetry.io/container-names" = name;
               }
             )
          );
      # Prometheus legacy annotations (if requested)
      promLegacyAnn = let p = cfg.prometheus or { enable = false; }; in
        if (p.enable or false) && (p.kind or "PodMonitor") == "Annotations" then (
          let
            annPort = if (p.port or null) != null then p.port else toString serviceCfg.port;
            annPath = p.path or null;
          in {}
            // { "prometheus.io/scrape" = "true"; "prometheus.io/port" = annPort; }
            // (lib.optionalAttrs (annPath != null) { "prometheus.io/path" = annPath; })
        ) else {};

      # Pod security context and /tmp writable emptyDir
      psec = cfg.podSecurity or { enable = false; };
      psecEnabled = psec.enable or false;
      psecContext = if psecEnabled then {
        fsGroup = 1069;
        fsGroupChangePolicy = "OnRootMismatch";
        seccompProfile = { type = "RuntimeDefault"; };
      } else null;
      tmpVolName = if psecEnabled then (psec.tmpVolumeName or "writable-tmp") else null;
      tmpVol = if psecEnabled then [ { name = tmpVolName; emptyDir = {}; } ] else [];
      tmpMount = if psecEnabled then [ { name = tmpVolName; mountPath = "/tmp"; readOnly = false; } ] else [];

      # Default env injection
      denv = cfg.defaultEnv or { enable = false; };
      denvEnabled = denv.enable or false;
      portStr = toString serviceCfg.targetPort;
      clusterName = cfg.clusterName or "";
      clientId = if (denv.clientIdOverride or null) != null then denv.clientIdOverride else "${namespace}:${name}";
      baseEnv = if denvEnabled then [
        { name = "NAIS_APP_NAME"; value = name; }
        { name = "NAIS_NAMESPACE"; value = namespace; }
        { name = "NAIS_APP_IMAGE"; value = cfg.image; }
        { name = "NAIS_CLUSTER_NAME"; value = clusterName; }
        { name = "NAIS_CLIENT_ID"; value = clientId; }
        { name = "LOG4J_FORMAT_MSG_NO_LOOKUPS"; value = "true"; }
        { name = "PORT"; value = portStr; }
        { name = "BIND_ADDRESS"; value = "0.0.0.0:" + portStr; }
      ] else [];
      gcpEnv = if denvEnabled && ((denv.googleTeamProjectId or null) != null) then [
        { name = "GOOGLE_CLOUD_PROJECT"; value = denv.googleTeamProjectId; }
        { name = "GCP_TEAM_PROJECT_ID"; value = denv.googleTeamProjectId; }
      ] else [];
      # Observability: build OTEL env when autoInstrumentation enabled
      ai = (obs.autoInstrumentation or { enabled = false; });
      otelEnabled = ai.enabled or false;
      otelDestIds = map (d: d.id) (ai.destinations or []);
      otelBackend = if otelDestIds == [] then null else lib.concatStringsSep ";" otelDestIds;
      existingOtelAttrs = cfg.env.OTEL_RESOURCE_ATTRIBUTES or null;
      existingPairs =
        if existingOtelAttrs == null then [] else
          lib.filter (s: s != "") (lib.splitString "," existingOtelAttrs);
      filterOut = key: pairs: lib.filter (p: (lib.substring 0 (lib.stringLength key + 1) p) != (key + "=")) pairs;
      extraPairs = filterOut "service.name" (filterOut "service.namespace" existingPairs);
      basePairs = [ "service.name=${name}" "service.namespace=${namespace}" ]
        ++ (lib.optional (otelBackend != null) ("nais.backend=" + otelBackend));
      otelAttrs = lib.concatStringsSep "," (basePairs ++ extraPairs);
      mkOtelEnv =
        let coll = ai.collector or null; in
        if !otelEnabled || coll == null then [] else [
          { name = "OTEL_SERVICE_NAME"; value = name; }
          { name = "OTEL_RESOURCE_ATTRIBUTES"; value = otelAttrs; }
          { name = "OTEL_EXPORTER_OTLP_ENDPOINT"; value = (if (coll.tls or false) then "https://" else "http://") + coll.service + "." + coll.namespace + ":" + toString (coll.port or 4317); }
          { name = "OTEL_EXPORTER_OTLP_PROTOCOL"; value = (coll.protocol or "grpc"); }
          { name = "OTEL_EXPORTER_OTLP_INSECURE"; value = (if (coll.tls or false) then "false" else "true"); }
        ];
      envBase = (ensureEnv cfg.env);
      envNoOtel = lib.filter (e: (e.name or "") != "OTEL_RESOURCE_ATTRIBUTES") envBase;
      envFinal = envNoOtel ++ baseEnv ++ gcpEnv ++ mkOtelEnv;
      # Aiven secret/env/volumes injection
      sanitizeInst = s:
        lib.toUpper (lib.replaceStrings ["-" "." ":" "/" " "] ["_" "_" "_" "_" "_"] s);
      aivenKafkaEnv =
        let ks = aivenKafka; in
        if ks == null || (ks.secretName or null) == null then [] else [
          { name = "KAFKA_CERTIFICATE"; valueFrom.secretKeyRef = { name = ks.secretName; key = "KAFKA_CERTIFICATE"; }; }
          { name = "KAFKA_PRIVATE_KEY"; valueFrom.secretKeyRef = { name = ks.secretName; key = "KAFKA_PRIVATE_KEY"; }; }
          { name = "KAFKA_BROKERS"; valueFrom.secretKeyRef = { name = ks.secretName; key = "KAFKA_BROKERS"; }; }
          { name = "KAFKA_SCHEMA_REGISTRY"; valueFrom.secretKeyRef = { name = ks.secretName; key = "KAFKA_SCHEMA_REGISTRY"; }; }
          { name = "KAFKA_SCHEMA_REGISTRY_USER"; valueFrom.secretKeyRef = { name = ks.secretName; key = "KAFKA_SCHEMA_REGISTRY_USER"; }; }
          { name = "KAFKA_SCHEMA_REGISTRY_PASSWORD"; valueFrom.secretKeyRef = { name = ks.secretName; key = "KAFKA_SCHEMA_REGISTRY_PASSWORD"; }; }
          { name = "KAFKA_CA"; valueFrom.secretKeyRef = { name = ks.secretName; key = "KAFKA_CA"; }; }
          { name = "AIVEN_CA"; valueFrom.secretKeyRef = { name = ks.secretName; key = "AIVEN_CA"; optional = true; }; }
          { name = "KAFKA_CREDSTORE_PASSWORD"; valueFrom.secretKeyRef = { name = ks.secretName; key = "KAFKA_CREDSTORE_PASSWORD"; }; }
        ] ++ (
          if (ks.mountCredentials or true) then [
            { name = "KAFKA_CERTIFICATE_PATH"; value = (ks.mountPath or "/var/run/secrets/nais.io/kafka") + "/kafka.crt"; }
            { name = "KAFKA_PRIVATE_KEY_PATH"; value = (ks.mountPath or "/var/run/secrets/nais.io/kafka") + "/kafka.key"; }
            { name = "KAFKA_CA_PATH"; value = (ks.mountPath or "/var/run/secrets/nais.io/kafka") + "/ca.crt"; }
            { name = "KAFKA_KEYSTORE_PATH"; value = (ks.mountPath or "/var/run/secrets/nais.io/kafka") + "/client.keystore.p12"; }
            { name = "KAFKA_TRUSTSTORE_PATH"; value = (ks.mountPath or "/var/run/secrets/nais.io/kafka") + "/client.truststore.jks"; }
          ] else []
        );
      aivenOpenSearchEnv =
        let os = aivenOpenSearch; in
        if os == null || (os.secretName or null) == null then [] else [
          { name = "OPEN_SEARCH_USERNAME"; valueFrom.secretKeyRef = { name = os.secretName; key = "OPEN_SEARCH_USERNAME"; }; }
          { name = "OPEN_SEARCH_PASSWORD"; valueFrom.secretKeyRef = { name = os.secretName; key = "OPEN_SEARCH_PASSWORD"; }; }
          { name = "OPEN_SEARCH_URI"; valueFrom.secretKeyRef = { name = os.secretName; key = "OPEN_SEARCH_URI"; }; }
          { name = "OPEN_SEARCH_HOST"; valueFrom.secretKeyRef = { name = os.secretName; key = "OPEN_SEARCH_HOST"; optional = true; }; }
          { name = "OPEN_SEARCH_PORT"; valueFrom.secretKeyRef = { name = os.secretName; key = "OPEN_SEARCH_PORT"; optional = true; }; }
          { name = "AIVEN_CA"; valueFrom.secretKeyRef = { name = os.secretName; key = "AIVEN_CA"; optional = true; }; }
        ];
      aivenValkeyEnv = lib.concatMap (v:
        let sn = v.secretName or null; in
        if sn == null then [] else (
          let suffix = sanitizeInst v.instance; in [
            { name = "VALKEY_USERNAME_" + suffix; valueFrom.secretKeyRef = { name = sn; key = "VALKEY_USERNAME_" + suffix; }; }
            { name = "VALKEY_PASSWORD_" + suffix; valueFrom.secretKeyRef = { name = sn; key = "VALKEY_PASSWORD_" + suffix; }; }
            { name = "VALKEY_URI_" + suffix; valueFrom.secretKeyRef = { name = sn; key = "VALKEY_URI_" + suffix; }; }
            { name = "VALKEY_HOST_" + suffix; valueFrom.secretKeyRef = { name = sn; key = "VALKEY_HOST_" + suffix; optional = true; }; }
            { name = "VALKEY_PORT_" + suffix; valueFrom.secretKeyRef = { name = sn; key = "VALKEY_PORT_" + suffix; optional = true; }; }
            { name = "REDIS_USERNAME_" + suffix; valueFrom.secretKeyRef = { name = sn; key = "REDIS_USERNAME_" + suffix; }; }
            { name = "REDIS_PASSWORD_" + suffix; valueFrom.secretKeyRef = { name = sn; key = "REDIS_PASSWORD_" + suffix; }; }
            { name = "REDIS_URI_" + suffix; valueFrom.secretKeyRef = { name = sn; key = "REDIS_URI_" + suffix; }; }
            { name = "REDIS_HOST_" + suffix; valueFrom.secretKeyRef = { name = sn; key = "REDIS_HOST_" + suffix; optional = true; }; }
            { name = "REDIS_PORT_" + suffix; valueFrom.secretKeyRef = { name = sn; key = "REDIS_PORT_" + suffix; optional = true; }; }
          ])
      ) aivenValkey;
      aivenEnv = aivenKafkaEnv ++ aivenOpenSearchEnv ++ aivenValkeyEnv;
      hostAliasesK8s = map (h: { hostnames = [ h.host ]; ip = h.ip; }) (cfg.hostAliases or []);

      # Optional aiven label when any aiven integration is configured
      anyAiven = aivenEnabled && ((aivenKafka != null) || (aivenOpenSearch != null) || (aivenValkey != []));
      labelsWithAiven = labelsWithTeam // (lib.optionalAttrs anyAiven { aiven = "enabled"; });

      # Secure logs: labels, volumes, initContainer, mounts
      secureLogsEnabled = slCfg.enable or false;
      secureLogsLabel = lib.optionalAttrs secureLogsEnabled { "secure-logs" = "enabled"; };
      # Logging flow labels
      logCfg = obs.logging or { enabled = false; };
      logDests = map (d: d.id) (logCfg.destinations or []);
      logLabels = if (logCfg.enabled or false) && (logDests != []) then (
        { "logs.nais.io/flow-default" = "false"; }
        // (lib.listToAttrs (map (id: { name = "logs.nais.io/flow-" + id; value = "true"; }) logDests))
      ) else {};
      secureLogsVolumes = if secureLogsEnabled then [
        { name = "secure-logs"; emptyDir = { sizeLimit = slCfg.sizeLimit or "128M"; }; }
        { name = "secure-logs-config"; configMap = { name = "secure-logs-fluentbit"; defaultMode = 420; }; }
        { name = "secure-logs-positiondb"; emptyDir = {}; }
        { name = "secure-logs-buffers"; emptyDir = {}; }
        { name = "writable-tmp"; emptyDir = {}; }
      ] else [];
      secureLogsMounts = if secureLogsEnabled then [
        { name = "secure-logs"; mountPath = "/secure-logs"; }
      ] else [];
      secureLogsInitContainers = if secureLogsEnabled then [
        {
          name = "secure-logs-fluentbit";
          image = slCfg.image;
          imagePullPolicy = "IfNotPresent";
          command = [ "/fluent-bit/bin/fluent-bit" "-c" "/fluent-bit/etc-operator/fluent-bit.conf" ];
          env = [
            { name = "NAIS_NODE_NAME"; valueFrom.fieldRef.fieldPath = "spec.nodeName"; }
            { name = "NAIS_NAMESPACE"; valueFrom.fieldRef.fieldPath = "metadata.namespace"; }
            { name = "NAIS_APP_NAME"; valueFrom.fieldRef.fieldPath = "metadata.labels['app']"; }
          ];
          resources = {
            limits.memory = "100M";
            requests = { cpu = "10m"; memory = "50M"; };
          };
          securityContext = {
            privileged = false;
            allowPrivilegeEscalation = false;
            capabilities.drop = [ "ALL" ];
            readOnlyRootFilesystem = true;
            runAsNonRoot = true;
            runAsUser = 1065;
            runAsGroup = 1065;
            seccompProfile.type = "RuntimeDefault";
          };
          volumeMounts = [
            { name = "secure-logs"; mountPath = "/secure-logs"; }
            { name = "secure-logs-config"; mountPath = "/fluent-bit/etc-operator"; readOnly = true; }
            { name = "secure-logs-positiondb"; mountPath = "/tail-db"; }
            { name = "secure-logs-buffers"; mountPath = "/buffers"; }
          ];
        }
      ] else [];

      deployment = mkDeployment {
        name = name;
        namespace = namespace;
        labels = labelsWithAiven // secureLogsLabel // logLabels // ttlLabel;
        annotations = annotations // reloaderAnn // ttlAnn;
        image = cfg.image;
        replicas = cfg.replicas;
        env = envFinal ++ aivenEnv
          ++ (let turl = (feCfg.telemetryUrl or null); in lib.optional (turl != null) { name = "NAIS_FRONTEND_TELEMETRY_COLLECTOR_URL"; value = turl; });
        command = cfg.command or [];
        ports = let
          ep = (if (promCfg.endpoints or []) != [] then lib.head promCfg.endpoints else { port = "http"; path = "/metrics"; });
          base = [{ name = "http"; containerPort = serviceCfg.targetPort; }];
          extra = if (promCfg.enable or false) && ((ep.port or "http") != "http") && ((promCfg.containerPort or null) != null) then [ { name = ep.port; containerPort = promCfg.containerPort; } ] else [];
        in base ++ extra;
        envFrom = lib.filter (x: x != {}) envFrom;
        resources = (if (resourcesCfg.limits or {}) == {} && (resourcesCfg.requests or {}) == {} then null else resourcesCfg);
        volumeMounts = let ks = aivenKafka; in (filesMounts ++ tmpMount ++ secureLogsMounts)
          ++ (if ks != null && (ks.secretName or null) != null && (ks.mountCredentials or true)
            then [ { name = "aiven-credentials"; mountPath = ks.mountPath or "/var/run/secrets/nais.io/kafka"; readOnly = true; } ] else [])
          ++ (let gen = feCfg.generatedConfig or null; in lib.optional (gen != null && (feCfg.telemetryUrl or null) != null) { name = "frontend-config"; mountPath = gen.mountPath; readOnly = true; });
        volumes = let ks = aivenKafka; in (filesVolumes ++ tmpVol ++ secureLogsVolumes)
          ++ (if ks != null && (ks.secretName or null) != null && (ks.mountCredentials or true)
            then [ { name = "aiven-credentials"; secret = { secretName = ks.secretName; items = [
              { key = "KAFKA_CERTIFICATE"; path = "kafka.crt"; }
              { key = "KAFKA_PRIVATE_KEY"; path = "kafka.key"; }
              { key = "KAFKA_CA"; path = "ca.crt"; }
              { key = "client.keystore.p12"; path = "client.keystore.p12"; }
              { key = "client.truststore.jks"; path = "client.truststore.jks"; }
            ]; }; } ] else [])
          ++ (let gen = feCfg.generatedConfig or null; in lib.optional (gen != null && (feCfg.telemetryUrl or null) != null) { name = "frontend-config"; configMap = { name = "${name}-frontend-config"; }; });
        initContainers = secureLogsInitContainers
          ++ (let v = vaultCfg; in
            if (v.enable or false) && (v.address or null) != null && (v.kvBasePath or null) != null && (v.authPath or null) != null then
              [
                {
                  name = "vks-init";
                  image = v.sidekickImage or "navikt/vault-sidekick:latest";
                  args = [
                    "-v=10" "-logtostderr" "-one-shot"
                    ("-vault=" + v.address)
                    "-save-token=/var/run/secrets/nais.io/vault/vault_token"
                  ] ++ (
                    let
                      defaultKV = v.kvBasePath + "/" + name + "/" + namespace;
                      defaultMount = "/var/run/secrets/nais.io/vault";
                      cnDefault = "-cn=secret:" + defaultKV + ":dir=" + defaultMount + ",fmt=flatten,retries=1";
                      userCns = lib.concatMap (p: [ ("-cn=secret:" + p.kvPath + ":dir=" + p.mountPath + ",fmt=flatten,retries=1") ]) (v.paths or []);
                    in [ cnDefault ] ++ userCns
                  );
                  env = [
                    { name = "VAULT_AUTH_METHOD"; value = "kubernetes"; }
                    { name = "VAULT_SIDEKICK_ROLE"; value = name; }
                    { name = "VAULT_K8S_LOGIN_PATH"; value = v.authPath; }
                  ];
                  volumeMounts = [
                    { name = "vault-volume"; mountPath = "/var/run/secrets/nais.io/vault"; subPath = "vault/var/run/secrets/nais.io/vault"; }
                  ] ++ (lib.concatMap (p: [ { name = "vault-volume"; mountPath = p.mountPath; subPath = "vault" + p.mountPath; } ]) (v.paths or []));
                }
              ]
            else []
          );
        livenessProbe = livenessProbe;
        readinessProbe = readinessProbe;
        startupProbe = startupProbe;
        lifecycle = lifecycle;
        podAnnotations = podAnn // promLegacyAnn;
        podSecurityContext = psecContext;
        tolerations = tolerations;
        affinity = affinity;
        hostAliases = hostAliasesK8s;
        serviceAccountName = if (saCfg.enable or false)
          then (if ((saCfg.name or null) != null) then saCfg.name else name)
          else null;
        imagePullSecrets = imagePullSecrets;
        terminationGracePeriodSeconds = cfg.terminationGracePeriodSeconds or null;
        strategy = strategy;
      };
      # gRPC handling: change Service port name to grpc and Ingress annotation
      isGrpc = (serviceCfg.protocol or "http") == "grpc";

      service = lib.optional serviceCfg.enable (mkService {
        name = name;
        namespace = namespace;
        labels = labelsWithAiven;
        annotations = annotations;
        port = serviceCfg.port;
        targetPort = if isGrpc then "http" else serviceCfg.targetPort;
        portName = if isGrpc then "grpc" else "http";
        type = serviceCfg.type;
      });
      ingress = lib.optional (ingressCfg.enable && ingressCfg.host != null) (mkIngress ({
        name = name;
        namespace = namespace;
        labels = labelsWithAiven;
        annotations = annotations
          // (lib.optionalAttrs isGrpc { "nginx.ingress.kubernetes.io/backend-protocol" = "GRPC"; "nginx.ingress.kubernetes.io/use-regex" = "true"; });
        host = ingressCfg.host;
        path = ingressCfg.path;
        pathType = ingressCfg.pathType;
        servicePort = serviceCfg.port;
      } // (lib.optionalAttrs (ingressCfg.tls != null) { tls = ingressCfg.tls; })));
      # Redirect ingresses
      redirectIngresses =
        let
          stripScheme = url:
            let u1 = lib.removePrefix "https://" url;
                u2 = lib.removePrefix "http://" u1;
            in lib.elemAt (lib.splitString "/" u2) 0;
        in lib.concatMap (r:
          let host = stripScheme r.from; target = r.to; in [
            {
              apiVersion = "networking.k8s.io/v1";
              kind = "Ingress";
              metadata = {
                name = name + "-redirect";
                inherit namespace;
                labels = labelsWithAiven;
                annotations = annotations // {
                  "nginx.ingress.kubernetes.io/rewrite-target" = target + "/$1";
                  "nginx.ingress.kubernetes.io/use-regex" = "true";
                };
              };
              spec = {
                rules = [
                  { inherit host; http.paths = [ {
                      path = "/(.*)?";
                      pathType = "ImplementationSpecific";
                      backend.service = { inherit name; port.number = serviceCfg.port; };
                    } ]; }
                ];
              };
            }
          ]) (ingressCfg.redirects or []);
      hpa = lib.optional hpaCfg.enable (mkHPA ({
        inherit name namespace;
        minReplicas = hpaCfg.minReplicas;
        maxReplicas = hpaCfg.maxReplicas;
      }
        // (lib.optionalAttrs ((hpaCfg.targetCPUUtilizationPercentage or null) != null) {
          targetCPUUtilizationPercentage = hpaCfg.targetCPUUtilizationPercentage;
        })
        // (lib.optionalAttrs ((hpaCfg.kafka or null) != null) {
          kafka = hpaCfg.kafka;
        }))
      );
      pdb = lib.optional (pdbCfg.enable or false) (mkPDB ({ name = name; namespace = namespace; labels = labelsWithTeam; annotations = annotations; }
        // (lib.optionalAttrs (pdbCfg ? minAvailable) { minAvailable = pdbCfg.minAvailable; })
        // (lib.optionalAttrs (pdbCfg ? maxUnavailable) { maxUnavailable = pdbCfg.maxUnavailable; })));
      serviceAccount = lib.optional (saCfg.enable or false) (mkServiceAccount {
        inherit namespace;
        name = (if ((saCfg.name or null) != null) then saCfg.name else name);
        annotations = saCfg.annotations or {};
        labels = labelsWithTeam;
      });
      configMaps = lib.mapAttrsToList (n: cm: mkConfigMap {
        name = n;
        inherit namespace;
        data = cm.data or {};
        labels = labelsWithTeam;
        annotations = annotations;
      }) cmCfg;
      # Frontend generated config (nais.js)
      frontendConfig =
        let
          gen = feCfg.generatedConfig or null;
          turl = feCfg.telemetryUrl or null;
        in if gen == null || turl == null then [] else (
          let
            cmName = "${name}-frontend-config";
            js = ''
export default {
  telemetryCollectorURL: '${turl}',
  app: {
    name: '${name}',
    version: '' + ''
  }
};
'';
            cm = mkConfigMap {
              name = cmName;
              inherit namespace;
              labels = labelsWithTeam;
              annotations = annotations;
              data = { "nais.js" = js; };
            };
          in [ cm ]
        );
      networkPolicy = lib.optional (npCfg.enable or false) (mkNetworkPolicy ({ name = name; namespace = namespace; labels = labelsWithTeam; annotations = annotations; }
        // (lib.optionalAttrs (npCfg ? policyTypes) { policyTypes = npCfg.policyTypes; })
        // (lib.optionalAttrs (npCfg ? podSelector) { podSelector = npCfg.podSelector; })
        // (lib.optionalAttrs (npCfg ? ingress) { ingress = npCfg.ingress; })
        // (lib.optionalAttrs (npCfg ? egress) { egress = npCfg.egress; })));
      # accessPolicy -> a generated NetworkPolicy named "${name}-access"
      accessNetworkPolicy =
        let
          # Optional ports block
          mkPorts = ports: if ports == [] then [] else map (p: { port = p; }) ports;
          inbound = apCfg.inbound or {};
          inPorts = inbound.ports or [];
          allowSameNs = inbound.allowSameNamespace or false;
          allowedNs = inbound.allowedNamespaces or [];
          allowedApps = inbound.allowedApps or [];
          inboundRules =
            let
              sameNsPeer = { namespaceSelector = { matchLabels = { "kubernetes.io/metadata.name" = namespace; }; }; };
              sameNs = if allowSameNs then [ { from = [ sameNsPeer ]; ports = mkPorts inPorts; } ] else [];
              nsRules = lib.concatMap (ns: [ { from = [ { namespaceSelector = { matchLabels = { "kubernetes.io/metadata.name" = ns; }; }; } ]; ports = mkPorts inPorts; } ]) allowedNs;
              appRules = lib.concatMap (appName: [ {
                from = [ { podSelector = { matchLabels = { app = appName; }; }; } ];
                ports = mkPorts inPorts;
              } ]) allowedApps;
            in sameNs ++ nsRules ++ appRules;
          outbound = apCfg.outbound or {};
          allowAll = outbound.allowAll or true;
          obNs = outbound.allowedNamespaces or [];
          obCidrs = (outbound.allowedCIDRs or []) ++ (if (aivenRange != null && aivenRange != "") then [ aivenRange ] else []);
          obPorts = outbound.allowedPorts or [];
          obAllowDNS = outbound.allowDNS or false;
          # If OTEL collector is configured, allow egress to it
          otelEgress = if otelEnabled && (ai.collector or null) != null then [
            {
              to = [ { namespaceSelector = { matchLabels = { "kubernetes.io/metadata.name" = ai.collector.namespace; }; };
                       podSelector = { matchLabels = (ai.collector.labels or {}); }; } ];
            }
          ] else [];
          egressRules = if allowAll then otelEgress else (
            let
              nsPeers = map (ns: { namespaceSelector = { matchLabels = { "kubernetes.io/metadata.name" = ns; }; }; }) obNs;
              cidrPeers = map (cidr: { ipBlock = { inherit cidr; }; }) obCidrs;
              ports = mkPorts obPorts;
              dnsRule = if obAllowDNS then [ { ports = [ { protocol = "UDP"; port = 53; } ]; } ] else [];
              baseRule = if (nsPeers ++ cidrPeers) == [] && ports == [] then [] else [ ({ to = nsPeers ++ cidrPeers; } // (lib.optionalAttrs (ports != []) { inherit ports; })) ];
            in baseRule ++ dnsRule ++ otelEgress
          );
          policyTypes = []
            ++ (if inboundRules != [] then [ "Ingress" ] else [])
            ++ (if egressRules != [] then [ "Egress" ] else []);
        in lib.optional (apCfg.enable or false && (inboundRules != [] || egressRules != []))
          (mkNetworkPolicy {
            name = "${name}-access";
            namespace = namespace;
            labels = labelsWithTeam;
            annotations = annotations;
            podSelector = { app = name; };
            policyTypes = policyTypes;
            ingress = inboundRules;
            egress = egressRules;
          });
      tracingNetworkPolicy = lib.optional (otelEnabled && (ai.collector or null) != null) (
        mkNetworkPolicy {
          name = "${name}-tracing";
          namespace = namespace;
          labels = labelsWithTeam;
          annotations = annotations;
          policyTypes = [ "Egress" ];
          podSelector = { app = name; };
          egress = [ { to = [ { namespaceSelector = { matchLabels = { "kubernetes.io/metadata.name" = ai.collector.namespace; }; };
                                 podSelector = { matchLabels = (ai.collector.labels or {}); }; } ]; } ];
        }
      );
      # Prometheus scraping resource
      serviceMonitor = lib.optional ((promCfg.enable or false) && ((promCfg.kind or "PodMonitor") != "Annotations")) (
        let ep = (if (promCfg.endpoints or []) != [] then lib.head promCfg.endpoints else { port = "http"; path = "/metrics"; }); in
        if (promCfg.kind or "PodMonitor") == "PodMonitor" then
          mkPodMonitor {
            inherit name namespace;
            labels = labelsWithAiven;
            path = ep.path or "/metrics";
            port = ep.port or "http";
            annotations = annotations;
          }
        else
          mkServiceMonitor ({
            inherit name namespace;
            labels = labelsWithAiven;
            annotations = annotations;
            endpoints = [ { port = ep.port or "http"; path = ep.path or "/metrics"; } ];
            selector = { matchLabels = { app = name; }; };
          })
      );
      # AivenApplication (if any aiven integration configured)
      aivenAppSpec = {}
        // (lib.optionalAttrs (aivenKafka != null && ((aivenKafka.pool or null) != null) && aivenKafka.pool != "") {
          kafka = { pool = aivenKafka.pool; };
        })
        // (lib.optionalAttrs (aivenOpenSearch != null && ((aivenOpenSearch.instance or null) != null) && aivenOpenSearch.instance != "") {
          openSearch = {
            instance = "opensearch-${namespace}-${aivenOpenSearch.instance}";
            access = aivenOpenSearch.access or "read";
          };
        })
        // (lib.optionalAttrs (aivenValkey != []) {
          valkey = map (v: { instance = v.instance; access = v.access or "read"; }) aivenValkey;
        });
      aivenApplication = lib.optional (anyAiven) (mkAivenApplication {
        inherit name namespace;
        labels = labelsWithAiven;
        annotations = annotations;
        spec = aivenAppSpec;
      });

      # Optional creation of Valkey service instances
      valkeyResources = lib.concatMap (v:
        if aivenManageInstances && (aivenProject != null && aivenProject != "")
        then [ (mkAivenValkey {
          name = "valkey-${namespace}-${v.instance}";
          namespace = namespace;
          project = aivenProject;
          plan = v.plan or "startup-4";
          appTag = name;
          labels = labelsWithAiven;
          annotations = annotations;
        }) ]
        else []
      ) aivenValkey;

      kafkaStream = lib.optional (aivenKafka != null && (aivenKafka.streams or false) && ((aivenKafka.pool or null) != null) && aivenKafka.pool != "") (mkKafkaStream {
        inherit name namespace;
        pool = aivenKafka.pool;
        labels = labelsWithAiven;
        annotations = annotations;
      });

      fqdnPolicy = lib.optional ((fqdnCfg.enable or false) || ((apCfg.enable or false) && fqdnFromAP != [])) (mkFQDNNetworkPolicy {
        name = "${name}-fqdn";
        appName = name;
        namespace = namespace;
        labels = labelsWithAiven;
        annotations = annotations;
        rules = fqdnRulesCombined;
      });
      secrets = lib.mapAttrsToList (n: s: mkSecret ({
        name = n;
        inherit namespace;
        type = s.type;
      } // (lib.optionalAttrs (s.data != {}) { data = s.data; })
        // (lib.optionalAttrs (s.stringData != {}) { stringData = s.stringData; }))) secretsCfg;
      # GCP resources (StorageBucket)
      gcpBuckets = lib.concatMap (b:
        if (gcpCfg.projectId or null) != null then [ (mkStorageBucket {
          name = b.name;
          namespace = namespace;
          projectId = gcpCfg.projectId;
          location = b.location or "europe-north1";
          deletionPolicy = b.deletionPolicy or "abandon";
          labels = labelsWithTeam;
          annotations = annotations;
        }) ] else []
      ) (gcpCfg.buckets or []);
      # GCP BigQuery datasets (NAIS CRD) + Project IAM jobUser binding
      bqDatasets = lib.concatMap (d:
        let
          googleProjectId = gcpCfg.googleProjectId or gcpCfg.projectId or null;
          teamProjectId = gcpCfg.projectId or null;
          saName = name + "-" + namespace;
          saEmail = if googleProjectId == null then null else "${saName}@${googleProjectId}.iam.gserviceaccount.com";
          normName = lib.toLower (lib.replaceStrings [" " "-" "."] ["_" "_" "_"] d.name);
          role = if (d.permission or "READ") == "READWRITE" then "WRITER" else "READER";
          dataset = {
            apiVersion = "google.nais.io/v1";
            kind = "BigQueryDataset";
            metadata = ({ name = name; inherit namespace; }
              // (lib.optionalAttrs (d.cascadingDelete or false) { annotations."cnrm.cloud.google.com/delete-contents-on-destroy" = "true"; }));
            spec = ({ name = normName; location = "europe-north1"; access = (if saEmail == null then [] else [ { inherit role; userByEmail = saEmail; } ]); }
              // (lib.optionalAttrs ((d.description or null) != null) { description = d.description; }));
          };
          iam = if teamProjectId != null && saEmail != null then [
            {
              apiVersion = "iam.cnrm.cloud.google.com/v1beta1";
              kind = "IAMPolicyMember";
              metadata = { name = saName; inherit namespace; annotations."cnrm.cloud.google.com/project-id" = teamProjectId; };
              spec = { member = "serviceAccount:${saEmail}"; role = "roles/bigquery.jobUser"; resourceRef = { kind = "Project"; };
              };
            }
          ] else [];
        in [ dataset ] ++ iam
      ) (gcpCfg.bigQueryDatasets or []);
      # Optional IAM helpers for buckets (service account + workload identity + viewer)
      gcpIam =
        let
          # Simple name (no hashing) for golden stability
          saName = name + "-" + namespace;
          googleProjectId = gcpCfg.googleProjectId or gcpCfg.projectId or null;
          teamProjectId = gcpCfg.projectId or null;
          iam = gcpCfg.iam or { createServiceAccount = false; enableWorkloadIdentityBinding = false; grantBucketViewer = false; };
          needSa = (iam.createServiceAccount or false) && (googleProjectId != null);
          firstBucketName = if (gcpCfg.buckets or []) == [] then null else (lib.head gcpCfg.buckets).name;
        in []
          ++ (lib.optional needSa (mkIAMServiceAccount {
            name = saName; projectId = googleProjectId; displayName = name; namespace = "serviceaccounts";
            annotations = { "nais.io/team" = namespace; };
          }))
          ++ (lib.optional ((iam.enableWorkloadIdentityBinding or false) && needSa) (mkIAMPolicy {
            name = saName; namespace = "serviceaccounts"; projectId = googleProjectId; memberNamespace = namespace; memberName = name;
          }))
          ++ (lib.optional ((iam.grantBucketViewer or false) && (teamProjectId != null) && (googleProjectId != null) && (firstBucketName != null)) (mkIAMPolicyMember {
            name = saName; namespace = namespace; teamProjectId = teamProjectId; googleProjectId = googleProjectId; bucketName = firstBucketName;
          }));
      res = [ deployment ]
        ++ service
        ++ ingress
        ++ redirectIngresses
        ++ hpa
        ++ pdb
        ++ serviceAccount
        ++ networkPolicy
        ++ accessNetworkPolicy
        ++ tracingNetworkPolicy
        ++ aivenApplication
        ++ kafkaStream
        ++ valkeyResources
        ++ fqdnPolicy
        ++ serviceMonitor
        ++ secrets
        ++ configMaps
        ++ gcpIam
        ++ bqDatasets
        ++ gcpBuckets
        ++ frontendConfig;
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
      configMaps = configMaps ++ frontendConfig;
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
nixerator.lib.buildApp { app = {
  name = "myapp";
  namespace = "default";
  image = "repo/image:tag";
  replicas = 2;
  service.enable = true;
  ingress.enable = true; ingress.host = "myapp.example.com";
  hpa.enable = true; hpa.maxReplicas = 4;
  pdb.enable = true; pdb.minAvailable = 1;
  serviceAccount.enable = true;
}; }.yaml
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
nixerator.lib.buildApp { app = {
  name = "myapp";
  namespace = "default";
  image = "repo/image:tag";
  replicas = 2;
  service.enable = true;
  ingress.enable = true; ingress.host = "myapp.example.com";
  hpa.enable = true; hpa.maxReplicas = 4;
  pdb.enable = true; pdb.minAvailable = 1;
  serviceAccount.enable = true;
}; }.yaml
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
