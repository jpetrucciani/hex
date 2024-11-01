{ _compat ? import ./flake-compat.nix
, pkgs ? import _compat.inputs.nixpkgs { overlays = [ pog.overlay ]; }  # TODO: document this, or fix it so we don't have to rely on the end user to provide pog in their pkgs
, pog ? import _compat.inputs.pog { }
, system ? pkgs.system
}:
let
  params = { inherit system pkgs; };
  hex = import ./hex params;
in
hex
