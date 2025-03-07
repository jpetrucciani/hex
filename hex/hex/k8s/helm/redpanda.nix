# This module contains a [redpanda](https://github.com/redpanda-data/redpanda) chart
# values here: https://github.com/redpanda-data/helm-charts/blob/main/charts/operator/values.yaml
{ hex, ... }:
let
  redpanda = rec {
    defaults = {
      name = "redpanda";
      namespace = "redpanda";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-4-40;
      v0-4-40 = _v "0.4.40" "1nwla1dj7p60c1xhc0qwbjya6f1l2h0bl4mlkh0b2syxdq2ah90f"; # 2025-03-04
    };
    chart_url = version: "https://github.com/redpanda-data/helm-charts/releases/download/operator-${version}/operator-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
redpanda
