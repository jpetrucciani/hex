# 🪄 hex

[![uses nix](https://img.shields.io/badge/uses-nix-%237EBAE4)](https://nixos.org/)

`hex` is an opinionated abstraction layer that brings the power of [Nix](https://nixos.org/) to [Kubernetes](https://kubernetes.io/) configuration management. It allows you to write declarative, composable "spells" that generate Kubernetes resources with all the benefits of the Nix ecosystem. Get your YAML nightmare under control, and keep things [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)!

## ✨ Features

- **Declarative Configuration**: Write your Kubernetes configs using Nix's powerful expression language
- **Composable Building Blocks**: Write functions to orchestrate other functions! Easy to snap things together
- **Pre-built modules**: Modules/functions for popular tools like ArgoCD, Prometheus, Grafana, and many more
- **Smart Diffing**: See exactly what will change before applying updates to your cluster
- **Built-in Safety**: Server-side diffs by default, with proper validation of resources
- **Helm Integration**: Seamlessly incorporate Helm charts into your configurations
- **Custom Resource Support**: First-class support for CRDs and custom resources
- **Development Friendly**: Built-in support for dry runs and partial deployments
- **[beta] ArgoCD plugin**: ArgoCD plugin is WIP! Deploying ArgoCD with `hex` will auto-configure the hex plugin

## 🚀 Quick Start

1. Install hex:

regular fetchTarball + import:

```nix
let
  pkgs = import
    (fetchTarball {
      name = "unstable-2024-10-31";
      url = "https://github.com/NixOS/nixpkgs/archive/2d2a9ddbe3f2c00747398f3dc9b05f7f2ebb0f53.tar.gz";
      sha256 = "1v6gpivg8mj4qapdp0y5grapnlvlw8xyh5bjahq9i50iidjr3587";
    })
    { };
  _hex = import
    (fetchTarball {
      name = "hex-2024-10-31";
      # note, you'll probably want to grab a commit sha for this instead of `main`!
      url = "https://github.com/jpetrucciani/hex/main.tar.gz";
      # this is necessary, but you can find it by letting nix try to evaluate this!
      sha256 = "";
    })
    { };
  paths = with _hex; [
    hex
    hexcast # not needed, unless you want to use this directly!
  ];
in
pkgs.buildEnv {
  name = "hextest";
  paths = paths;
  buildInputs = paths;
}
```

with flakes:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hex.url = "github:jpetrucciani/hex";
  };
  outputs = { self, nixpkgs, hex, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs { inherit system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        nativeBuildInputs = [
          hex.hex
        ];
      };
    };
}
```

2. Create your first spell (e.g., `specs.nix`):

**Note: `specs.nix` is the default target when `hex` is run without a specific target (`-t TARGET_FILE`) or without `-a/--all`**

```nix
{ hex }:
let
    # remember this is just nix code, so you can use any normal language features!
    inherit (hex.k8s.svc) metabase;
in
hex [
    # every entry in this list will be evaluated + rendered
    # lists will be flattened!

    # if an entry is a function, it will be called with an empty attrset
    hex.k8s.svc.litellm      # equivalent to: (hex.k8s.svc.litellm {})

    # pass attrs in to override default functionality, or to provide required attrs
    (metabase { domain = "metabase.cobi.dev"; })

    # if an entry is a yaml file path, it will be merged into the set of all rendered specs
    ./other_k8s_spec.yaml    # includes this file in the rendered output documents

    # also, use toYAMLDoc to use arbitrary attrsets!
    (hex.toYAMLDoc {
        apiVersion = "v1";
        kind = "ServiceAccount";
        metadata = {
            annotations.source = "hex";
            name = "my-service-account";
            namespace = "default";
        };
    })

    # TODO: show a helm chart example
]
```

3. Cast your spell:

```bash
hex

# or, to target a specific file:
hex -t specs.nix

#or, to load all hex files in the current directory:
hex -a    # also:
hex --all
```

## 🎭 Available Modules

hex comes with a rich set of pre-built modules for common Kubernetes applications:

- **Databases**: PostgreSQL, Redis, MongoDB, Elastic
- **Monitoring**: Prometheus, Grafana
- **CI/CD**: ArgoCD, GitLab Runner
- **Identity**: Authentik
- **Ingress**: Kong, Nginx, Traefik
- **Observability**: Sentry
- **Services**: generic, best practices service creation module
- **Cron**: easy + powerful cron job configuration module
- **And many more!**

## 🔧 Advanced Usage

```bash
# only render and print to stdout
hex --render -t specs.nix

# eval a sring instead of using a file (useful for testing hex itself, or deploying things one-off!)
# '{hex}:' is prepended to the eval string
hex --evaluate --render 'hex [hex.k8s.svc.litellm]'

# dryrun, just show diff
hex --dryrun -t specs.nix

# filter to just the CRDs
# useful to apply the CRDs from a helm chart before attempting to deploy the rest!
hex --crds -t specs.nix

# force apply, don't perform a diff, and don't ask for a confirmation
hex --force -t specs.nix

# clientside diff. available in case you need it, but I would avoid!
hex --clientside -t specs.nix

# evaluate all
```

## 📚 Components

- **hex**: Main command-line tool for applying configurations to clusters. Written with [pog](https://pog.gemologic.dev/)!
- **hexcast**: Core rendering engine that transforms Nix configurations into Kubernetes resources
- **nixrender**: Low-level tool for rendering Nix expressions

## Demo

TODO
