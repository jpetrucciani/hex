# [otf](https://github.com/jpetrucciani/otf) is an open source terraform cloud alternative
{ hex, ... }:
let
  name = "otfd";
  otf = rec {
    defaults = {
      inherit name;
      namespace = name;
    };
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./otf.json; };
    values_url = "https://github.com/leg100/otf-charts/blob/master/charts/otfd/values.yaml";
    chart_url = version: if version == "0.3.13" then "https://github.com/jpetrucciani/otf-charts/releases/download/otf-${version}/otf-${version}.tgz" else "https://github.com/leg100/otf-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
otf
