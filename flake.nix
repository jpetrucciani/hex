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
  };

  outputs = { nixpkgs, flake-utils, pog, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ pog.overlays.${system}.default ]; };
        hex = import ./. { inherit pkgs system; };
        hexpkgs = { inherit (hex) hex hexcast nixrender deps test; };
      in
      {
        packages = hexpkgs;
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
