# [keda](https://github.com/kedacore/keda) is a Kubernetes-based Event Driven Autoscaling component
{ hex, ... }:
let
  name = "keda";
  keda = rec {
    defaults = {
      inherit name;
      namespace = "default";
    };
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./keda.json; };
    chart_url = version: "https://kedacore.github.io/charts/keda-${version}.tgz";
    values_url = "https://github.com/kedacore/charts/blob/main/keda/values.yaml";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
keda
