# a hex module for [airbyte](https://github.com/airbytehq/airbyte), an ETL pipeline tool
{ hex, ... }:
let
  airbyte = rec {
    defaults = {
      name = "airbyte";
      namespace = "airbyte";
    };
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./airbyte.json; };
    chart_url = version: "https://airbytehq.github.io/helm-charts/airbyte-${version}.tgz";
    values_url = "https://github.com/airbytehq/airbyte-platform/blob/main/charts/airbyte/values.yaml";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
airbyte
