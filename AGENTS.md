# Repository Guidelines

## Project Structure & Module Organization
This repository is Nix-first and centered on Kubernetes config generation.

- `hex/default.nix`: packaging for `hex`, `hexcast`, and `nixrender`.
- `hex/hex/`: core library and Kubernetes modules.
- `hex/hex/k8s/`: service, addon, and Helm-oriented modules (`helm/*.nix`, `svc/*.nix`).
- `docs/`: VitePress documentation and examples.
- `.github/workflows/`: CI checks, docs build/deploy, and chart auto-update automation.
- `default.nix` and `flake.nix`: dev shell, packages, and integration test entrypoints.

## Build, Test, and Development Commands
- `nix develop`: enter the pinned toolchain shell.
- `nix build .#hex`: build the main CLI.
- `nix build .#test && ./result/bin/test`: run integration checks that render real module outputs.
- `nix develop -c nixpkgs-fmt --check .`: enforce Nix formatting.
- `nix develop -c statix check`: run static lint checks.
- `nix develop -c deadnix -f -_ -l .`: detect dead Nix code.
- `bun run docs:dev` / `bun run docs:build`: serve/build docs from `docs/`.

## Coding Style & Naming Conventions
- Use 2-space indentation and keep lines readable (Prettier `printWidth: 100`).
- Favor small composable Nix functions and attribute sets over large monolith expressions.
- Keep module names descriptive and kebab-cased where appropriate, for example `open-webui.nix`.
- Prefer explicit version namespaces for charts/services (example: `version.latest`, `version.v1-0-17`).

## Testing Guidelines
- Primary tests are integration-style render checks via `.#test`.
- Validate changed modules by rendering them directly (example: `hex --render -t specs.nix`).
- Run lint/format checks before opening a PR to match CI behavior.

## Commit & Pull Request Guidelines
- Follow existing commit style: short, imperative, lowercase summaries (example: `add search to docs`).
- Use focused update commits for dependency/chart bumps (example: `update metabase -> 0.58.5`).
- `[auto] ...` prefixes are reserved for automation workflows.
- PRs should include:
  - clear summary of affected modules/paths,
  - linked issue/context when relevant,
  - local command results for lint/test/build.
