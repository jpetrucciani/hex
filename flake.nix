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
        hexpkgs = { inherit (hex) hex hexcast nixrender; };
      in
      {
        packages = hexpkgs;
        defaultPackage = hex;

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
