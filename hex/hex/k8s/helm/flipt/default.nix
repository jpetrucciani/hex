# [flipt](https://github.com/flipt-io/flipt) is a feature flag service built with Go
{ hex, ... }:
let
  name = "flipt";
  flipt = rec {
    defaults = {
      inherit name;
      namespace = name;
    };
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./flipt.json; };
    chart_url = version: "https://github.com/flipt-io/helm-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
    values_url = "";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
flipt
