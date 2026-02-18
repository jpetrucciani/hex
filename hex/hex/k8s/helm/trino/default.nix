{ hex, ... }:
let
  trino =
    let
      name = "trino";
      defaults = {
        inherit name;
        namespace = "trinot";
      };
      chart_url = version: "https://github.com/trinodb/charts/releases/download/${name}-${version}/${name}-${version}.tgz";
      values_url = "https://github.com/trinodb/charts/blob/main/charts/trino/values.yaml";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    in
    {
      inherit defaults chart chart_url values_url;
      version = hex.k8s._.versionMap { inherit chart; versionFile = ./trino.json; };
    };
  gateway =
    let
      name = "trino-gateway";
      defaults = {
        inherit name;
        namespace = "trino";
      };
      chart_url = version: "https://github.com/trinodb/charts/releases/download/${name}-${version}/${name}-${version}.tgz";
      values_url = "https://github.com/trinodb/charts/blob/main/charts/trino/values.yaml";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    in
    {
      inherit defaults chart chart_url values_url;
      version = hex.k8s._.versionMap { inherit chart; versionFile = ./gateway.json; };
    };
in
{ inherit trino gateway; }
