Nixerator is a Nix flake that helps you define common Kubernetes resources (Deployments, Services, Ingresses, HPAs, Secrets etc) as Nix, and render them to YAML.

It's an experiement in what if all resources were static artifacts and there was no app spec at all?

Quick start
- Prereqs: Nix with flakes enabled.
- Build example manifests (application module): `nix build .#manifests && echo && cat result`
 - Advanced example: `nix build .#manifests-advanced && echo && cat result`
 - Pretty JSON view: `make print-json` (after a build)

Simple consumption (as a library)
- In your flake, add input `nixerator` and build from a plain attrset via the canonical builder:
  - `let eval = nixerator.lib.buildApp { app = { name = "myapp"; image = "..."; service = { enable = true; }; }; }; in pkgs.writeText "manifest.yaml" eval.yaml`
- The builder returns a structured result with `cfg`, `options`, `resources`, and `yaml`.
- See `templates/basic/flake.nix` for a minimal consumer flake and `templates/kitchen-sink/flake.nix` for a full-feature consumer you can copy into your repo.

Modules workflow (recommended)
- Evaluate module to manifests: `nix build .#manifests && cat result`
- Advanced resources: `nix build .#manifests-advanced && cat result`
- Everything example: `nix build .#manifests-everything && cat result`
- Generate module docs (Org): `nix build .#docs && sed -n '1,80p' result`

The module lives at `nixosModules.app` and can be evaluated with `lib.evalModules`. Use `nixerator.lib.buildApp { app = { ... }; }` (or `nixerator.lib.evalAppModules` directly) to get `cfg`, `options`, `resources`, and `yaml`.

What’s inside
- `flake.nix` exposes the typed application module and builds `manifests-basic` by evaluating it. It also exposes extension modules and an extended example, plus a simple consumer entry under `lib.simple`.
- `lib/default.nix` provides helpers: `mkDeployment`, `mkService`, `mkIngress`, `mkHPA`, `mkSecret`, `mkPDB`, `mkServiceAccount`, `mkConfigMap`, `mkNetworkPolicy`, `mkServiceMonitor`, `mkApp`, `evalAppModules`, and `renderManifests`.
- `modules/app.nix` defines the core application interface (typed NixOS-style module).
- `modules/ext/*.nix` add resourcecreator-style features: `pdb`, `serviceAccount`, `configMaps`, `networkPolicy`, `prometheus`.
  - New: `accessPolicy` for high-level inbound/outbound rules that render a NetworkPolicy named `${app}-access`.
- `examples/app-basic.nix` is a module config demonstrating the core interface.
- `examples/app-extended.nix` demonstrates the extended interface (PDB, SA, ConfigMap, NetworkPolicy, ServiceMonitor).
- Consumer flakes you can copy:
  - `templates/basic/flake.nix` (basic: Deployment/Service/Ingress/HPA/Secrets, etc.)
  - `templates/kitchen-sink/flake.nix` (kitchen-sink: includes accessPolicy, fqdnPolicy, pod security, probes, filesFrom, scheduling, prometheus, etc.)

Recently added toward Naiserator parity
- Probes: `probes.liveness|readiness|startup` (HTTP, timing fields, optional port).
- Resources: `resources.requests/limits` for cpu/memory strings.
- envFrom: `envFrom` supports ConfigMaps and Secrets.
- filesFrom: `filesFrom` mounts ConfigMaps/Secrets/PVC/EmptyDir at `mountPath`.
- Command, image pull secrets, terminationGracePeriodSeconds on Pod.
- Access policy: `accessPolicy.enable = true;` with `inbound.allowSameNamespace`, `inbound.allowedNamespaces`, `inbound.allowedApps`, and `outbound.allowAll/allowedNamespaces/allowedCIDRs/allowedPorts/allowDNS`.
  - Example: `nix build .#manifests-accesspolicy && cat result` (see `examples/app-access.nix`).
- FQDNPolicy (GKE CRD): `fqdnPolicy.enable = true; fqdnPolicy.rules = [ { host = "api.github.com"; ports = [443]; } ];`.
  - Also: `accessPolicy.outbound.allowedFQDNs` auto-feeds FQDN rules when `accessPolicy.enable = true`.
- Lifecycle preStop hooks: `preStop.exec.command = ["..."]` or `preStop.http.{path,port}`.
- Deployment strategy: `strategy.type = "Recreate"|"RollingUpdate"` with `strategy.rollingUpdate.{maxSurge,maxUnavailable}`.
  - Example: `nix build .#manifests-advanced && cat result` (see `examples/app-advanced.nix`).
- Pod security defaults: `podSecurity.enable = true` (FSGroup 1069, RuntimeDefault seccomp, /tmp EmptyDir mount).
- Default env: `defaultEnv.enable = true` injects NAIS_* and PORT/BIND_ADDRESS (+GCP when configured).
- Observability annotations: `observability.defaultContainer`, `observability.logformat`, `observability.logtransform`.
- Reloader + TTL: `reloader.enable = true`, `ttl.enable = true` (+ `ttl.duration` or `ttl.killAfter`).
- Team label default: `labelsDefaults.addTeam = true` adds `team = namespace` on resources.
- Scheduling hooks: `scheduling.antiAffinity` (required|preferred, topologyKey), `scheduling.tolerations` list.
- Prometheus: `prometheus.enable = true; prometheus.kind = "PodMonitor"|"ServiceMonitor"; prometheus.endpoints = [ { port = "http"; path = "/metrics"; } ];`.
- Aiven (alpha): `aiven.enable = true;` with support for `aiven.kafka.pool`, `aiven.openSearch.{instance,access}`, and `aiven.valkey = [ { instance, access, plan, createInstance } ]`.
  - Emits `AivenApplication` (aiven.nais.io/v1) when Kafka/OpenSearch/Valkey is configured.
  - Emits `Stream` (kafka.nais.io/v1) when `aiven.kafka.streams = true`.
  - Optionally emits `Valkey` (aiven.io/v1alpha1) resources when `aiven.manageInstances = true` and `aiven.project` is set.
  - Adds label `aiven=enabled` on pod template to match Naiserator behavior.
  - Optionally append `aiven.rangeCIDR` to `accessPolicy.outbound.allowedCIDRs` when egress is restricted.
- Ingress parity:
  - gRPC: set `service.protocol = "grpc"` to emit Ingress annotation `nginx.ingress.kubernetes.io/backend-protocol=GRPC` and change Service port name to `grpc` with targetPort `http`.
  - Redirects: `ingress.redirects = [ { from = "https://old"; to = "https://new"; } ]` to emit a second Ingress with `rewrite-target: <to>/$1` and regex path `/(.*)?`.

Docs generation
- `lib.orgDocsFromOptions` and `lib.orgDocsFromEval` turn the evaluated options tree into an Emacs Org file listing option names, types, defaults, and descriptions.

Testing and goldens
- Run tests: `make test` (builds manifests via flake and diffs against `tests/golden/*.yaml`).
- Update goldens: `make update-golden` (or `UPDATE_GOLDEN=1 tests/run.sh`).
- Dev shell includes `kubeconform` and `yq` for local validation if you want to run it manually.
 - `nix flake check` runs golden comparisons against `tests/golden`, but skips `kubeconform` to avoid network access.

Notes on kubeconform
- Kubeconform is not run in flake checks (no network in many environments). Use the dev shell to run it manually, or enable it in CI where network access is allowed.

Use the library in another flake
- Add input: `nixerator.url = "github:YOUR_ORG/nixerator"` (or a local path while iterating).
- Then: `nixerator.lib.mkDeployment { name = "my-app"; image = "my/image:tag"; }` etc., combine with `renderManifests` and write via `pkgs.writeText`.

Notes
- This is a minimal scaffold to get started. Shapes are intentionally simple and can be extended (probes, volumes, resources, multiple ports/paths, advanced ingress, secret/data encodings, etc.).
