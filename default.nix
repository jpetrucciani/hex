{ _compat ? import ./flake-compat.nix
, pkgs ? import _compat.inputs.nixpkgs { overlays = [ pog.overlay ]; }  # TODO: document this, or fix it so we don't have to rely on the end user to provide pog in their pkgs
, pog ? import _compat.inputs.pog { }
, system ? pkgs.system
}:
let
  params = { inherit system pkgs; };
  hex = import ./hex params;
  deps = import ./hex/hex/deps.nix { inherit pkgs; };
  test =
    let
      heval = "${hex.hex}/bin/hex -r -e";
      tests = [
        "svc.litellm {}"
        ''svc.metabase {domain = "meme.com";}''
        "external-secrets.version.latest {}"
      ];
      test_case = x: ''
        echo "testing '${x}'"
        ${heval} 'hex.k8s.${x}' | ${pkgs.yq-go}/bin/yq e 'document_index' | ${pkgs.coreutils}/bin/tail -n 1
      '';
      test_script = pkgs.lib.concatStringsSep "\n" (map test_case tests);
    in
    pkgs.writers.writeBashBin "test" test_script;
in
hex // { inherit deps test; }
