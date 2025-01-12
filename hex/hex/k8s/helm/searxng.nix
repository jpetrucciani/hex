# [searxng](https://github.com/searxng/searxng/) is a free internet metasearch engine which aggregates results from various search services and databases
{ hex, ... }:
let
  searxng = rec {
    defaults = {
      name = "searxng";
      namespace = "default";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v1-0-0;
      v1-0-0 = _v "1.0.0" "0zrgwl2nypyhl9rhqxd8i6613capsj7wh028h4mzdsd09xbcrym2"; # 2022-06-08
    };
    chart_url = version: "https://github.com/searxng/searxng-helm-chart/releases/download/searxng-${version}/searxng-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
searxng
