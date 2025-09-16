Nixerator is a Nix flake that helps you define common Kubernetes resources (Deployments, Services, Ingresses, HPAs, Secrets) as Nix, and render them to YAML.

Quick start
- Prereqs: Nix with flakes enabled.
- Build example manifests (application module): `nix build .#manifests-basic && echo && cat result`

Modules workflow (recommended)
- Evaluate module to manifests: `nix build .#manifests-module-basic && cat result`
- Generate module docs (Org): `nix build .#docs-org && sed -n '1,80p' result`

The module lives at `nixosModules.app` and can be evaluated with `lib.evalModules`. Use `lib.evalAppModules { modules = [ self.nixosModules.app yourModule ]; }` to get `cfg`, `options`, `resources`, and `yaml`.

What’s inside
- `flake.nix` exposes the typed application module and builds `manifests-basic` by evaluating it.
- `lib/default.nix` provides helpers: `mkDeployment`, `mkService`, `mkIngress`, `mkHPA`, `mkSecret`, `mkApp`, `evalAppModules`, and `renderManifests`.
- `modules/app.nix` defines the application interface (typed NixOS-style module).
- `examples/app-basic.nix` is a module config demonstrating the interface.
 - `modules/app.nix` defines a NixOS-style module with typed options under `app.*`.
 - `examples/app-basic.nix` is a module config demonstrating the typed interface.

Docs generation
- `lib.orgDocsFromOptions` and `lib.orgDocsFromEval` turn the evaluated options tree into an Emacs Org file listing option names, types, defaults, and descriptions.

Use the library in another flake
- Add input: `nixerator.url = "github:YOUR_ORG/nixerator"` (or a local path while iterating).
- Then: `nixerator.lib.mkDeployment { name = "my-app"; image = "my/image:tag"; }` etc., combine with `renderManifests` and write via `pkgs.writeText`.

Notes
- This is a minimal scaffold to get started. Shapes are intentionally simple and can be extended (probes, volumes, resources, multiple ports/paths, advanced ingress, secret/data encodings, etc.).
