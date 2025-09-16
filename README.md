Nixerator is a Nix flake that helps you define common Kubernetes resources (Deployments, Services, Ingresses, HPAs, Secrets) as Nix, and render them to YAML.

Quick start
- Prereqs: Nix with flakes enabled.
- Build example manifests: `nix build .#manifests-basic && echo && cat result`

What’s inside
- `flake.nix` exposes a small library and an example package `manifests-basic` that builds a multi-document YAML.
- `lib/default.nix` provides helpers: `mkDeployment`, `mkService`, `mkIngress`, `mkHPA`, `mkSecret`, `mkApp`, and `renderManifests`.
- `examples/basic.nix` shows composing an app from the helpers.

Use the library in another flake
- Add input: `nixerator.url = "github:YOUR_ORG/nixerator"` (or a local path while iterating).
- Then: `nixerator.lib.mkDeployment { name = "my-app"; image = "my/image:tag"; }` etc., combine with `renderManifests` and write via `pkgs.writeText`.

Notes
- This is a minimal scaffold to get started. Shapes are intentionally simple and can be extended (probes, volumes, resources, multiple ports/paths, advanced ingress, secret/data encodings, etc.).
