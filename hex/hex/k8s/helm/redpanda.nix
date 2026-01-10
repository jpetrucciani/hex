# This module contains a [redpanda](https://github.com/redpanda-data/redpanda) chart
# values here: https://github.com/redpanda-data/redpanda-operator/blob/main/charts/redpanda/chart/values.yaml
{ hex, ... }:
let
  redpanda = rec {
    defaults = {
      name = "redpanda";
      namespace = "redpanda";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v25-3-1;
      v25-3-1 = _v "25.3.1" "1gpkg8ny1jzn0jxbfnbc1rd3nb8pa1xlf5d9ir7r6rahasbnjwh2"; # 2025-12-12
      v25-2-1 = _v "25.2.1" "1kwdfs9l1qgq78xl4qb89a1vqm9x805df6d4j93sq5yg3lsz8wk4"; # 2025-12-03
      v25-1-4 = _v "25.1.4" "16dp4cl1srnacxbiaznc5s6yjmdlr90mqvb7ifmz07x0bjbgpd7w"; # 2025-11-06
      v25-1-3 = _v "25.1.3" "1b2y3q4di6hjksj1hy3dkgdzsg7kkhqk2rmlcs6hs3rhacvaf36x"; # 2025-08-07
      v25-1-2 = _v "25.1.2" "0r6m7kzw6z069kdffgnn9218mc7l5j515nljkbr9j2s0gxhdmh51"; # 2025-07-31
      v25-1-1 = _v "25.1.1" "01p0jn8x4slmqjpgjy8jdxl2l0kp7vn8h08g950dw8af93vn0wh9"; # 2025-07-29
    };
    chart_url = version: "https://github.com/redpanda-data/redpanda-operator/releases/download/operator/v${version}/operator-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
redpanda
