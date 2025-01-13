{ pkgs, ... }:
let
  inherit (pkgs.lib) getExe' getExe;
  pog = if isFunctor pkgs.pog then pkgs.pog else pkgs.pog.pog;
  isAttrSet = value: builtins.isAttrs value;
  hasAttrKey = key: value: (isAttrSet value) && (builtins.hasAttr key value);
  isFunctor = hasAttrKey "__functor";
  core = "${pkgs.coreutils}/bin";
  hexcast =
    let
      _ = {
        sed = "${pkgs.gnused}/bin/sed";
        realpath = "${core}/realpath";
        yq = "${pkgs.yq-go}/bin/yq";
        prettier = "${pkgs.nodePackages.prettier}/bin/prettier --write --config ${../prettier.config.js}";
        mktemp = "${pkgs.coreutils}/bin/mktemp --suffix=.yaml";
        nix = "${pkgs.lix}/bin/nix";
      };
    in
    pog {
      name = "hexcast";
      version = "0.0.6";
      description = "a quick and easy way to use nix to render (cast) various other types of config files!";
      flags = [
        {
          name = "format";
          description = "the output format to use. use either yaml or json!";
          default = "yaml";
        }
        {
          name = "crds";
          description = "filter to only the crds (k8s specific)";
          bool = true;
        }
      ];
      arguments = [{ name = "nix_file"; }];
      script = helpers: with helpers; ''
        ${var.notEmpty "1"} && spell="$1"
        ${var.empty "spell"} && spell="$(${_.mktemp})" && cp /dev/stdin "$spell"
        spell_render="$(${_.mktemp})"
        fullpath="$(${_.realpath} "$spell")"
        debug "casting $fullpath - hex files at ${./hex}"
        ${_.nix} eval --raw --impure --expr "import ${./hex}/spell.nix ${pkgs.path} \"$fullpath\"" >"$spell_render"
        debug "formatting $spell_render"
        ${_.prettier} --parser "$format" "$spell_render" &>/dev/null
        debug "removing blank docs in $spell_render"
        # remove empty docs
        ${_.sed} -E -z -i 's#---(\n+---)*#---#g' "$spell_render"
        ${flag "crds"} && ${_.yq} e -i '. | select(.kind == "CustomResourceDefinition")' "$spell_render"
        cat "$spell_render"
      '';
    };
in
{
  inherit hexcast;
  nixrender =
    let
      nix = "${pkgs.lix}/bin/nix";
    in
    pog {
      name = "nixrender";
      description = "a quick and easy way to use nix to render various other config files!";
      flags = [ ];
      arguments = [
        { name = "nix_file"; }
      ];
      script = ''
        template="$1"
        rendered="$(${nix}/bin/nix eval --raw -f "$template")"
        echo "$rendered"
      '';
    };

  hex =
    let
      version = "0.0.9";
    in
    pog {
      inherit version;
      name = "hex";
      description = "a quick and easy way to render full kubespecs from nix files";
      flags = [
        {
          name = "target";
          description = "the file to render specs from";
          default = "./specs.nix";
        }
        {
          name = "all";
          description = "render all hex files in the current directory (ignoring gitignored files)";
          bool = true;
        }
        {
          name = "dryrun";
          description = "just run the diff, don't prompt to apply";
          bool = true;
        }
        {
          name = "render";
          description = "only render and patch, do not diff or apply";
          bool = true;
        }
        # {
        #   name = "check";
        #   description = "whether to check the hex for deprecations";
        #   bool = true;
        # }
        {
          name = "crds";
          description = "filter down to just the CRDs (useful for initial deployments)";
          bool = true;
        }
        {
          name = "clientside";
          description = "run the diff on the clientside instead of serverside";
          short = "";
          bool = true;
        }
        {
          name = "prettify";
          description = "whether to run prettier on the hex output yaml";
          bool = true;
        }
        {
          name = "force";
          description = "force apply the resulting hex without a diff (WARNING - BE CAREFUL)";
          bool = true;
        }
        {
          name = "evaluate";
          description = "evaluate an in-line hex script";
        }
        {
          name = "version";
          description = "print version and exit";
          short = "";
          bool = true;
        }
      ];
      script =
        let
          steps = {
            render = "render";
            patch = "patch";
            diff = "diff";
            apply = "apply";
          };
          _ = {
            k = getExe' pkgs.kubectl "kubectl";
            hc = getExe hexcast;
            delta = getExe' pkgs.delta "delta";
            mktemp = "${pkgs.coreutils}/bin/mktemp";
            rg = "${pkgs.ripgrep}/bin/rg";
            sort = "${pkgs.coreutils}/bin/sort";
            prettier = "${pkgs.nodePackages.prettier}/bin/prettier --write --config ${../prettier.config.js}";
          };
        in
        helpers: with helpers; ''
          ${flag "version"} && echo "hex: ${version}" && exit 0
          export USE_GKE_GCLOUD_AUTH_PLUGIN=True
          if ${var.notEmpty "evaluate"}; then
            target=$(${_.mktemp})
            cat <<EOF >"$target"
            {hex, pkgs}:
            $evaluate
          EOF
          fi
          side="true"
          ${flag "clientside"} && side="false"
          rendered=$(${_.mktemp})
          diffed=$(${_.mktemp})
          debug "''${GREEN}render to '$rendered'"
          ${timer.start steps.render}
          if ${flag "all"}; then
            debug "rendering all hex files!"
            source_files=$(${_.rg} -t nix -l "hex" . | ${_.sort})
            debug "found: $source_files"
            for f in $source_files; do
              debug "rendering $f"
              echo -e "### HEX: $f\n" >>"$rendered"
              ${_.hc} ''${crds:+--crds} "$f" >>"$rendered"
              render_exit_code=$?
              echo -e "### HEX END: $f\n" >>"$rendered"
              if [ "$render_exit_code" -ne 0 ]; then
                die "hexcast failed on '$f'!" 2
              fi
            done
          else
            ${file.notExists "target"} && die "the file to render ('$target') does not exist!"
            ${_.hc} ''${crds:+--crds} "$target" >"$rendered"
            render_exit_code=$?
          fi
          render_runtime=${timer.stop steps.render}
          debug "''${GREEN}rendered to '$rendered' in $render_runtime''${RESET}"
          if [ "$render_exit_code" -ne 0 ]; then
            die "hexcast failed!" 2
          fi
          ${flag "prettify"} && ${_.prettier} --parser yaml "$rendered" >/dev/null
          if ${flag "render"}; then
            cat "$rendered"
            exit 0
          fi
          if ${flag "force"}; then
            ${timer.start steps.apply}
            ${_.k} apply --force-conflicts --server-side="$side" -f "$rendered"
            apply_runtime=${timer.stop steps.apply}
            debug "''${GREEN}force applied '$rendered' in $apply_runtime''${RESET}"
            exit 0
          fi
          ${timer.start steps.diff}
          ${_.k} diff --force-conflicts --server-side="$side" -f "$rendered" >"$diffed"
          diff_exit_code=$?
          diff_runtime=${timer.stop steps.diff}
          debug "''${GREEN}diffed '$rendered' to '$diffed' in $diff_runtime [exit code $diff_exit_code]''${RESET}"
          if [ $diff_exit_code -ne 0 ] && [ $diff_exit_code -ne 1 ]; then
            die "diff of hex failed!" 3
          fi
          if [ -s "$diffed" ]; then
            debug "''${GREEN}changes detected!''${RESET}"
          else
            blue "no changes in hex detected!"
            exit 0
          fi
          ${_.delta} <"$diffed"
          ${flag "dryrun"} && exit 0
          echo "---"
          ${confirm {prompt="Would you like to apply these changes?";}}
          echo "---"
          ${timer.start steps.apply}
          ${_.k} apply --force-conflicts --server-side="$side" -f "$rendered"
          apply_runtime=${timer.stop steps.apply}
          debug "''${GREEN}applied '$rendered' in $apply_runtime''${RESET}"
        '';
    };
}
