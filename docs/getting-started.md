# Getting Started

## install

### fetchTarball + import

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
      url = "https://github.com/jpetrucciani/hex/archive/main.tar.gz";
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

or if you want to add it as an overlay to nixpkgs, you can add `pog.overlays.${system}.default` in your overlays for nixpkgs!

### flake

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
      _hex = hex.packages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        nativeBuildInputs = [
          _hex.hex
        ];
      };
    };
}
```

## usage

### help docs

```bash
# hex --help
Usage: hex [-t|--target VAR] [-a|--all] [-d|--dryrun] [-r|--render] [-c|--crds] [--clientside] [-p|--prettify] [-f|--force] [-e|--evaluate VAR] [--version]

a quick and easy way to render full kubespecs from nix files

Flags:
-t, --target          the file to render specs from [default: './specs.nix']
-a, --all             render all hex files in the current directory (ignoring gitignored files) [bool]
-d, --dryrun          just run the diff, don't prompt to apply [bool]
-r, --render          only render and patch, do not diff or apply [bool]
-c, --crds            filter down to just the CRDs (useful for initial deployments) [bool]
--clientside          run the diff on the clientside instead of serverside [bool]
-p, --prettify        whether to run prettier on the hex output yaml [bool]
-f, --force           force apply the resulting hex without a diff (WARNING - BE CAREFUL) [bool]
-e, --evaluate        evaluate an in-line hex script
--version             print version and exit [bool]
-h, --help            print this help and exit
-v, --verbose         enable verbose logging and info
--no-color            disable color and other formatting
```
