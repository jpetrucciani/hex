# [redpanda](https://github.com/redpanda/redpanda) is a Kafka API compatible streaming data platform for developers
{ hex, ... }:
let
  name = "redpanda";
  defaults = {
    inherit name;
    namespace = name;
  };
  chart_url = version: "https://github.com/redpanda-data/redpanda-operator/releases/download/operator/v${version}/operator-${version}.tgz";
  values_url = "https://github.com/redpanda-data/redpanda-operator/blob/main/operator/chart/values.yaml";
  chart = hex.k8s._.chart { inherit defaults chart_url; };
  netbox = {
    inherit defaults chart chart_url values_url;
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./redpanda.json; };
  };
in
netbox
