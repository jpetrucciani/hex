# [airflow](https://github.com/apache/airflow/) is a platform to programmatically author, schedule, and monitor workflows
{ hex, ... }:
let
  values_url = "https://github.com/airflow-helm/charts/blob/main/charts/airflow/values.yaml";
  name = "airflow";
  airflow = rec {
    defaults = {
      inherit name;
      namespace = "default";
    };
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./airflow.json; };
    chart_url = version: "https://downloads.apache.org/airflow/helm-chart/${version}/airflow-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
airflow
