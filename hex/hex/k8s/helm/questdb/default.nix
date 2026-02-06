# This module contains a [questdb](https://github.com/questdb/questdb) chart
# values here: https://github.com/questdb/questdb-kubernetes/blob/master/charts/questdb/values.yaml
{ hex, ... }:
let
  questdb = rec {
    defaults = {
      name = "questdb";
    };
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./questdb.json; };
    chart_url = version: "https://questdb.github.io/questdb-kubernetes/questdb-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
questdb
