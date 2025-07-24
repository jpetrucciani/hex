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
      latest = v1-0-9;
      v1-0-9 = _v "1.0.9" "15mb7zjgfdx7ddsghlhv3g07ia1f93hdxm1rvh05wqlipr6ca432"; # 2025-07-23
      v1-0-8 = _v "1.0.8" "00mln3j0hiyaans8agw8wxifw65ddy93vwp7xi71qbyc6rq9i15z"; # 2025-07-11
      v1-0-7 = _v "1.0.7" "0nvjvfkb89vld0k5mqnbcfaazlgnqyjf2x3is7g0kfnmipivskxs"; # 2025-05-30
      v1-0-5 = _v "1.0.5" "1rfkgp76f1mzwjb7y2b7z8d0g39cpyny7p2v32zifg1i7f48ivyn"; # 2025-04-28
      v0-42-1 = _v "0.42.1" "1p718y7fg85j59f6mr3jnv4izhb7xr290ijd0zpfbqqx3hssjiix"; # 2025-02-05
    };
    chart_url = version: "https://questdb.github.io/questdb-kubernetes/questdb-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
questdb
