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
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v2-12-3;
      v2-12-3 = _v "2.12.3" "0pdfabb08b2plfns4ax3xjrwmq6z30qgrkgb1y0w0fjzvm28wz7g"; # 2025-12-18
      v2-12-2 = _v "2.12.2" "0h2p8fp12473xxr2xk0fllcp95z28fdix16306x19v6rjxjn3x0i"; # 2025-11-19
    };
    chart_url = version: "https://github.com/nats-io/k8s/releases/download/nats-${version}/nats-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
nats
