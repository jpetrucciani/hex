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
      mktemp = "${pkgs.coreutils}/bin/mktemp --suffix=.yaml";
      tests = let num_docs = num: ''[ "$num_docs" -ne ${toString num} ] && echo "not the correct number of docs! expected ${toString num}, but got $num_docs" && exit 1''; in [
        { name = "litellm"; spec = "hex.k8s.svc.litellm {}"; check = num_docs 5; }
        { name = "lobe-chat"; spec = "hex.k8s.svc.lobe-chat {}"; check = num_docs 4; }
        { name = "metabase"; spec = ''hex.k8s.svc.metabase {domain = "meme.com";}''; check = num_docs 4; }
        { name = "external-secrets"; spec = "hex.k8s.external-secrets.version.latest {}"; check = num_docs 34; }
      ];
      test_case = x:
        let
          log = text: ''echo "[${x.name}] ${text}"'';
        in
        ''
          ${log "test"}
          rendered="$(${mktemp})"
          ${heval} '${x.spec}' >$rendered
          ${log "rendered to $rendered"}
          exit_code=$?
          num_docs="$(${pkgs.yq-go}/bin/yq e 'document_index' $rendered | ${pkgs.coreutils}/bin/tail -n 1)"
          ${log "exit code: $exit_code"}
          ${log "num docs: $num_docs"}
          ${x.check or ""}
        '';
      test_script = pkgs.lib.concatStringsSep "\n" (map test_case tests);
    in
    pkgs.writers.writeBashBin "test" test_script;
in
hex // { inherit deps test; }
