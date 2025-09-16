Nixerator is a Nix flake that helps you define common Kubernetes resources (Deployments, Services, Ingresses, HPAs, Secrets) as Nix, and render them to YAML.

Quick start
- Prereqs: Nix with flakes enabled.
- Build example manifests (application module): `nix build .#manifests && echo && cat result`
 - Advanced example: `nix build .#manifests-advanced && echo && cat result`
 - Pretty JSON view: `make print-json` (after a build)

Simple consumption (as a library)
- In your flake, add input `nixerator` and build from a plain attrset via the canonical builder:
  - `let eval = nixerator.lib.buildApp { app = { name = "myapp"; image = "..."; service = { enable = true; }; }; }; in pkgs.writeText "manifest.yaml" eval.yaml`
- The builder returns a structured result with `cfg`, `options`, `resources`, and `yaml`.
- See `examples/` for ready-to-copy module configs.

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

Docs generation
- `lib.orgDocsFromOptions` and `lib.orgDocsFromEval` turn the evaluated options tree into an Emacs Org file listing option names, types, defaults, and descriptions.

Testing and goldens
- Run tests: `make test` (builds manifests via flake and diffs against `tests/golden/*.yaml`).
- Update goldens: `make update-golden` (or `UPDATE_GOLDEN=1 tests/run.sh`).
- Dev shell includes `kubeconform` and `yq` for local validation if you want to run it manually.

Notes on kubeconform
- Flake checks use offline-friendly flags: `-strict -ignore-missing-schemas`.
- For stricter validation with network access, run kubeconform manually in the dev shell or configure CI to allow schema fetching.

Use the library in another flake
- Add input: `nixerator.url = "github:YOUR_ORG/nixerator"` (or a local path while iterating).
- Then: `nixerator.lib.mkDeployment { name = "my-app"; image = "my/image:tag"; }` etc., combine with `renderManifests` and write via `pkgs.writeText`.

Notes
- This is a minimal scaffold to get started. Shapes are intentionally simple and can be extended (probes, volumes, resources, multiple ports/paths, advanced ingress, secret/data encodings, etc.).
