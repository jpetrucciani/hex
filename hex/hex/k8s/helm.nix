# This module allows us to transparently use [helm](https://github.com/helm/helm) charts in hex spells!
{ hex, pkgs }:
let
  inherit (builtins) isFunction readFile;
  inherit (hex) concatMapStrings _if fetchGitChart fetchOCIChart;
  inherit (hex._) prettier sed yaml_sort yq;
  helm = rec {
    constants = {
      flags = {
        create-namespace = "--create-namespace";
      };
      ports = {
        all = "*";
        ftp = "21";
        ssh = "22";
        smtp = "25";
        https = "80,443";
        mysql = "3306";
        postgres = "5432";
        mongo = "27017";
      };
    };
    charts = {
      url = {
        github = { org, repo, repoName, chartName ? repoName, version }: "https://github.com/${org}/${repo}/releases/download/${repoName}-${version}/${chartName}-${version}.tgz";
      };
    };
    build = args: ''
      ---
      ${readFile (chart args).template}
    '';
    chart =
      { name
      , url
      , sha256
      , namespace ? "default"
      , values ? [ ]
      , valuesAttrs ? null
      , defaultValuesAttrs ? null
      , sets ? [ ]
      , version ? "0.0.0"
      , includeCRDs ? true
      , extraFlags ? [ ]
      , forceNamespace ? false
      , preRender ? ""
      , postRender ? ""
      , prettify ? true
      , sortYaml ? false
      , kubeVersion ? "1.31"
      , apiVersions ? ""
      , rev ? "" # only used for git charts
      , subPath ? "" # only used for git charts
      }:
      let
        chartFiles =
          if useGit then fetchGitChart { inherit sha256 url subPath rev; }
          else
            (if useOCI then fetchOCIChart else fetchTarball) {
              inherit sha256 url;
            };
        useOCI = pkgs.lib.hasPrefix "oci://" url;
        useGit = pkgs.lib.hasSuffix ".git" url;
        apiVersionOverrides = if apiVersions != "" then ''--api-versions '${apiVersions}' '' else "";
        allValues = values ++
          (if defaultValuesAttrs != null then [ (hex.valuesFile defaultValuesAttrs) ] else [ ]) ++
          (if valuesAttrs != null then [ (hex.valuesFile valuesAttrs) ] else [ ]);
      in
      rec {
        hookParams = {
          inherit chartFiles;
        };
        preRenderText = if isFunction preRender then preRender hookParams else preRender;
        postRenderText = if isFunction postRender then postRender hookParams else postRender;
        template = pkgs.runCommand "${name}-${version}-rendered.yaml" { } ''
          cp -r ${chartFiles}/* .
          ${preRenderText}
          ${pkgs.kubernetes-helm}/bin/helm template \
            --namespace '${namespace}' \
            --kube-version '${kubeVersion}' ${apiVersionOverrides} \
            ${_if includeCRDs "--include-crds"} \
            ${name} \
            ${concatMapStrings (x: "--values ${x} ") allValues} \
            ${concatMapStrings (x: "--set '${x}' ") sets} \
            ${concatMapStrings (x: "${x} ") extraFlags} \
            . >$out

          # remove empty docs
          ${sed} -E -z -i 's#---(\n+---)*#---#g' $out

          # force namespace (optional)
          ${_if forceNamespace ''${yq} e -i '(select (tag == "!!map" or tag== "!!seq") | .metadata.namespace) = "${namespace}"' $out''}
          ${_if forceNamespace ''${yq} e -i 'with (.items[]; .metadata.namespace = "${namespace}")' $out''}
          ${_if forceNamespace ''${yq} e -i 'del(.items | select(length==0))' $out''}
          ${_if forceNamespace ''${sed} -E -z -i 's#---(\n+\{\}\n+---)*#---#g' $out''}
          ${postRenderText}
          ${_if sortYaml ''${yaml_sort} <$out >$out.tmp''}
          ${_if sortYaml ''mv $out.tmp $out''}
          ${_if prettify ''${prettier} --parser yaml $out''}
        '';
      };
  };
in
helm
