# [airflow](https://github.com/apache/airflow/) is a platform to programmatically author, schedule, and monitor workflows
{ hex, ... }:
let
  # values here: https://github.com/airflow-helm/charts/blob/main/charts/airflow/values.yaml
  name = "airflow";
  airflow = rec {
    defaults = {
      inherit name;
      namespace = "default";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v1-18-0;
      v1-18-0 = _v "1.18.0" "1lp5xwbia9d790g6fpxiv0gszgm1yhmcwssixg4v6k39mnrqr6s6"; # 2025-07-13
    };
    chart_url = version: "https://downloads.apache.org/airflow/helm-chart/${version}/airflow-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
airflow
