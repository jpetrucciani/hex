# [open-webui](https://github.com/open-webui/open-webui) is a user-friendly AI interface
{ hex, ... }:
let
  name = "open-webui";
  # example values file here: https://github.com/open-webui/helm-charts/blob/main/charts/open-webui/values.yaml
  open-webui = rec {
    defaults = {
      inherit name;
      namespace = "default";
    };
    chart_url = version: "https://github.com/open-webui/helm-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./open-webui.json; };
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
open-webui
