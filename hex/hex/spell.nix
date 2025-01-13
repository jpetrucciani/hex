# this is the nix function that is actually run when you run the `hex` command
nixpkgs: SPELL:
let
  inherit (builtins) functionArgs isFunction intersectAttrs;
  pkgs = import nixpkgs { };
  deps = import ./deps.nix { inherit pkgs; };
  spell = import SPELL;
  output = if isFunction spell then spell (intersectAttrs (functionArgs spell) deps.params) else spell;
in
output
