# [robusta](https://github.com/robusta-dev/robusta) is a Kubernetes observability and automation, with an awesome Prometheus integration
{ hex, ... }:
let
  robusta = rec {
    defaults = {
      name = "robusta";
      namespace = "robusta";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-21-5;
      v0-21-5 = _v "0.21.5" "17akslcykw5m6gmzg44rwaaj9d58g3z3plwvnd3165k80b7a7yr0"; # 2025-02-19
    };
    chart_url = version: "https://robusta-charts.storage.googleapis.com/robusta-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
robusta
