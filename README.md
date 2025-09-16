Nixerator is a Nix flake that helps you define common Kubernetes resources (Deployments, Services, Ingresses, HPAs, Secrets) as Nix, and render them to YAML.

Quick start
- Prereqs: Nix with flakes enabled.
- Build example manifests (application module): `nix build .#manifests-basic && echo && cat result`
 - Pretty JSON view: `make print-json` (after a build)

Simple consumption (as a library)
- In your flake, add input `nixerator` and build YAML from a plain attrset:
  - `pkgs.writeText "manifest.yaml" (nixerator.lib.simple.yamlFromApp { name = "myapp"; image = "..."; service.enable = true; })`
- Or get a structured result (resources + yaml):
  - `nixerator.lib.simple.eval { app = { ... }; }`
- See `templates/basic/` for a ready-to-copy consumer flake.

Modules workflow (recommended)
- Evaluate module to manifests: `nix build .#manifests-module-basic && cat result`
- Extended resources: `nix build .#manifests-module-extended && cat result`
- Generate module docs (Org): `nix build .#docs-org && sed -n '1,80p' result`
 - Simple docs variant: `nix build .#docs-org-simple && sed -n '1,60p' result`

The module lives at `nixosModules.app` and can be evaluated with `lib.evalModules`. Use `lib.evalAppModules { modules = [ self.nixosModules.app yourModule ]; }` to get `cfg`, `options`, `resources`, and `yaml`.

What’s inside
- `flake.nix` exposes the typed application module and builds `manifests-basic` by evaluating it. It also exposes extension modules and an extended example, plus a simple consumer entry under `lib.simple`.
- `lib/default.nix` provides helpers: `mkDeployment`, `mkService`, `mkIngress`, `mkHPA`, `mkSecret`, `mkPDB`, `mkServiceAccount`, `mkConfigMap`, `mkNetworkPolicy`, `mkServiceMonitor`, `mkApp`, `evalAppModules`, and `renderManifests`.
- `modules/app.nix` defines the core application interface (typed NixOS-style module).
- `modules/ext/*.nix` add resourcecreator-style features: `pdb`, `serviceAccount`, `configMaps`, `networkPolicy`, `prometheus`.
- `examples/app-basic.nix` is a module config demonstrating the core interface.
- `examples/app-extended.nix` demonstrates the extended interface (PDB, SA, ConfigMap, NetworkPolicy, ServiceMonitor).

Docs generation
- `lib.orgDocsFromOptions` and `lib.orgDocsFromEval` turn the evaluated options tree into an Emacs Org file listing option names, types, defaults, and descriptions.

Testing and goldens
- Run tests: `make test` (builds manifests via flake and diffs against `tests/golden/*.yaml`).
- Update goldens: `make update-golden` (or `UPDATE_GOLDEN=1 tests/run.sh`).
- Flake checks: `nix flake check` runs golden comparison and kubeconform validation for `manifests-basic`, `manifests-module-basic`, and `manifests-module-extended`.
- Dev shell includes `kubeconform` and `yq` for local validation if you want to run it manually.

Notes on kubeconform
- Flake checks use offline-friendly flags: `-strict -ignore-missing-schemas`.
- For stricter validation with network access, run kubeconform manually in the dev shell or configure CI to allow schema fetching.

Use the library in another flake
- Add input: `nixerator.url = "github:YOUR_ORG/nixerator"` (or a local path while iterating).
- Then: `nixerator.lib.mkDeployment { name = "my-app"; image = "my/image:tag"; }` etc., combine with `renderManifests` and write via `pkgs.writeText`.

Notes
- This is a minimal scaffold to get started. Shapes are intentionally simple and can be extended (probes, volumes, resources, multiple ports/paths, advanced ingress, secret/data encodings, etc.).
