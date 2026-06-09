# [dremio]()
{ hex, ... }:
let
  dremio = rec {
    defaults = {
      name = "dremio";
      namespace = "default";
    };
    values_url = "https://github.com/dremio/dremio-cloud-tools/blob/master/charts/dremio_v2/values.yaml";
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./dremio.json; };
    chart_url = version: "oci://quay.io/dremio/dremio-helm:${version}";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
dremio
