{ hex, ... }:
rec {
  defaults = {
    name = "retool";
  };
  version = hex.k8s._.versionMap { inherit chart; versionFile = ./retool.json; };
  chart_url = version: "https://charts.retool.com/retool-${version}.tgz";
  values_url = "https://github.com/tryretool/retool-helm/blob/main/values.yaml";
  chart = hex.k8s._.chart { inherit defaults chart_url; };
}
