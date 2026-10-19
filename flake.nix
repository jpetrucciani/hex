{
  description = "pog";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-compat = {
      flake = false;
      url = "github:edolstra/flake-compat";
    };
    flake-utils.url = "github:numtide/flake-utils";
    pog.url = "github:jpetrucciani/pog";
    # Reuse the standard scanner generator without importing its whole package set.
    chart-scanners = {
      url = "github:jpetrucciani/nix/345a263bb1d9db8f119584842415c07910ea2358";
      flake = false;
    };
  };

  outputs = { nixpkgs, flake-utils, pog, chart-scanners, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ pog.overlays.default ]; };
        hex = import ./. { inherit pkgs system; };
        hexpkgs = { inherit (hex) hex hexcast nixrender deps test; };
        scannerTools = import "${chart-scanners}/mods/pog/helm.nix"
          (pkgs // { inherit (pkgs.pog) pog; })
          pkgs;
        chart_scan_opencost = scannerTools._chart_scan {
          name = "opencost";
          base_url = "https://opencost.github.io/opencost-helm-chart";
          chart_url = hex.deps.hex.k8s.opencost.chart_url "{1}";
          last = 3;
        };
      in
      {
        packages = hexpkgs // { inherit chart_scan_opencost; };
        defaultPackage = hex.hex;
        lib = {
          inherit (hex) docsIndex;
        };

        devShells = {
          default = pkgs.mkShell {
            nativeBuildInputs =
              let
                inherit (pkgs.pog) pog;
              in
              with pkgs; [
                bun
                deadnix
                kubeconform
                nixpkgs-fmt
                statix

                # hex
                hexpkgs.hex
                hexpkgs.hexcast
                hexpkgs.nixrender

                (pkgs.writers.writeBashBin "cursed_convert" ''
                  ${pkgs.gawk}/bin/awk '
                    match($0, /_v[[:space:]]+"([^"]+)"[[:space:]]+"([^"]+)"/, m) {
                      ver=m[1]; sha=m[2];
                      date="null"
                      if (match($0, /#[[:space:]]*([0-9]{4}-[0-9]{2}-[0-9]{2})/, d)) {
                        date="\"" d[1] "T00:00:00Z\""
                      }
                      printf "{\"version\":\"%s\",\"date\":%s,\"sha256\":\"%s\"}\n", ver, date, sha
                    }
                  ' "$1" | ${pkgs.jq}/bin/jq -s .
                '')
              ] ++ [
                (pog {
                  name = "docs";
                  script = ''
                    ${pkgs.bun}/bin/bun run docs:dev docs --host 0.0.0.0 "$@"
                  '';
                })
                (pog {
                  name = "build_docs";
                  script = ''
                    ${pkgs.bun}/bin/bun docs:build docs "$@"
                  '';
                })
              ];
          };
        };
      });
}
