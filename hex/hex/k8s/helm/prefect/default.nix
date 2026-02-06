# [prefect]()
{ hex, ... }:
let
  server =
    let
      name = "prefect-server";
      defaults = {
        inherit name;
        namespace = "prefect";
      };
      chart_url = version: "https://prefecthq.github.io/prefect-helm/charts/${name}-${version}.tgz";
      values_url = "https://github.com/prefect-community/prefect-chart/blob/main/charts/prefect/values.yaml";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    in
    {
      inherit defaults chart chart_url values_url;
      version = hex.k8s._.versionMap { inherit chart; versionFile = ./server.json; };
    };
  worker =
    let
      name = "prefect-worker";
      defaults = {
        inherit name;
        namespace = "prefect";
      };
      chart_url = version: "https://prefecthq.github.io/prefect-helm/charts/${name}-${version}.tgz";
      values_url = "https://github.com/prefect-community/prefect-chart/blob/main/charts/prefect/values.yaml";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    in
    {
      inherit defaults chart chart_url values_url;
      version = hex.k8s._.versionMap { inherit chart; versionFile = ./worker.json; };
    };
in
{ inherit server worker; }
