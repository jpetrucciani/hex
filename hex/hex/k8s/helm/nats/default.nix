# [nats](https://github.com/nats-io/k8s) is a cloud and edge native messaging system
{ hex, ... }:
let
  # values here: https://github.com/nats-io/k8s/blob/main/helm/charts/nats/values.yaml
  name = "nats";
  nats = rec {
    defaults = {
      inherit name;
      namespace = "default";
    };
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./nats.json; };
    chart_url = version: "https://github.com/nats-io/k8s/releases/download/nats-${version}/nats-${version}.tgz";
    values_url = "https://github.com/nats-io/k8s/blob/main/helm/charts/nats/values.yaml";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
nats
