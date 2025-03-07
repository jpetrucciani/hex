# This module contains a [questdb](https://github.com/questdb/questdb) chart
# values here: https://github.com/questdb/questdb-kubernetes/blob/master/charts/questdb/values.yaml
{ hex, ... }:
let
  questdb = rec {
    defaults = {
      name = "questdb";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-42-1;
      v0-42-1 = _v "0.42.1" "1p718y7fg85j59f6mr3jnv4izhb7xr290ijd0zpfbqqx3hssjiix"; # 2025-02-05
    };
    chart_url = version: "https://questdb.github.io/questdb-kubernetes/questdb-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
questdb
