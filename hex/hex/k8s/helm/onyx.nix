# This module contains an [onyx](https://github.com/onyx-dot-app/onyx) chart
# values here: https://github.com/onyx-dot-app/onyx/blob/main/deployment/helm/charts/onyx/values.yaml
{ hex, ... }:
let
  onyx = rec {
    defaults = {
      name = "onyx";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-3-1;
      v0-3-1 = _v "0.3.1" "1aj684hgjlbj4fay2g8d7sqg7k1mg65qqax7gm6p22nd8r3ylbni"; # 2025-09-23
    };
    chart_url = version: "https://onyx-dot-app.github.io/onyx/onyx-stack-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
onyx
