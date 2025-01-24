# this is the nix function that is actually run when you run the `hex` command
nixpkgs: arg:
let
  inherit (builtins) functionArgs isFunction intersectAttrs;
  pkgs = import nixpkgs { config = { }; overlays = [ ]; };
  deps = import ./deps.nix { inherit pkgs; };
in
(f: if arg.isRepl or false then _: deps.params else f arg)
  (
    SPELL:
    let
      spell = import SPELL;
      output = if isFunction spell then spell (intersectAttrs (functionArgs spell) deps.params) else spell;
    in
    output
  )
