# Helpers for [prometheus](https://github.com/prometheus/prometheus) related things in k8s land!
{ hex, ... }:
let
  inherit (hex) ifNotEmptyList ifNotNull toYAMLDoc;
  prom_chart = name: version: "https://github.com/prometheus-community/helm-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
in
{
  gmp = {
    pod_monitoring =
      { name
      , port
      , matchLabels
      , path ? "/metrics"
      , timeout ? null
      , namespace ? "default"
      , interval ? "30s"
      , metricRelabeling ? [ ]
      }:
      let
        monitor = {
          apiVersion = "monitoring.googleapis.com/v1";
          kind = "PodMonitoring";
          metadata = {
            inherit name namespace;
          };
          spec = {
            endpoints = [
              {
                inherit interval port path;
                ${ifNotEmptyList metricRelabeling "metricRelabeling"} = metricRelabeling;
                ${ifNotNull timeout "timeout"} = timeout;
              }
            ];
            selector = {
              inherit matchLabels;
            };
          };
        };
      in
      toYAMLDoc monitor;
  };
  kube-prometheus-stack = rec {
    defaults = {
      name = "prometheus";
      namespace = "default";
    };
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./kube-prometheus-stack.json; };
    values_url = "https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml";
    chart_url = prom_chart "kube-prometheus-stack";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
  adapter = rec {
    defaults = {
      name = "prometheus-adapter";
      namespace = "default";
    };
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./adapter.json; };
    values_url = "https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus-adapter/values.yaml";
    chart_url = prom_chart "prometheus-adapter";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
  pushgateway = rec {
    defaults = {
      name = "prometheus-pushgateway";
      namespace = "default";
    };
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./pushgateway.json; };
    values_url = "https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus-pushgateway/values.yaml";
    chart_url = prom_chart "prometheus-pushgateway";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
  exporters = {
    cloudwatch = rec {
      defaults = {
        name = "prometheus-cloudwatch-exporter";
        namespace = "default";
      };
      version = hex.k8s._.versionMap { inherit chart; versionFile = ./cloudwatch-exporter.json; };
      values_url = "https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus-cloudwatch-exporter/values.yaml";
      chart_url = prom_chart "prometheus-cloudwatch-exporter";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
    elasticsearch = rec {
      defaults = {
        name = "prometheus-elasticsearch-exporter";
        namespace = "default";
      };
      version = hex.k8s._.versionMap { inherit chart; versionFile = ./elasticsearch-exporter.json; };
      values_url = "https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus-elasticsearch-exporter/values.yaml";
      chart_url = prom_chart "prometheus-elasticsearch-exporter";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
    mongodb = rec {
      defaults = {
        name = "prometheus-mongodb-exporter";
        namespace = "default";
      };
      version = hex.k8s._.versionMap { inherit chart; versionFile = ./mongodb-exporter.json; };
      values_url = "https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus-mongodb-exporter/values.yaml";
      chart_url = prom_chart "prometheus-mongodb-exporter";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
    mysql = rec {
      defaults = {
        name = "prometheus-mysql-exporter";
        namespace = "default";
      };
      version = hex.k8s._.versionMap { inherit chart; versionFile = ./mysql-exporter.json; };
      values_url = "https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus-mysql-exporter/values.yaml";
      chart_url = prom_chart "prometheus-mysql-exporter";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
    nats = rec {
      defaults = {
        name = "prometheus-nats-exporter";
        namespace = "default";
      };
      version = hex.k8s._.versionMap { inherit chart; versionFile = ./nats-exporter.json; };
      values_url = "https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus-nats-exporter/values.yaml";
      chart_url = prom_chart "prometheus-nats-exporter";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
    postgres = rec {
      defaults = {
        name = "prometheus-postgres-exporter";
        namespace = "default";
      };
      version = hex.k8s._.versionMap { inherit chart; versionFile = ./postgres-exporter.json; };
      values_url = "https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus-postgres-exporter/values.yaml";
      chart_url = prom_chart "prometheus-postgres-exporter";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
    redis = rec {
      defaults = {
        name = "prometheus-redis-exporter";
        namespace = "default";
      };
      version = hex.k8s._.versionMap { inherit chart; versionFile = ./redis-exporter.json; };
      values_url = "https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus-redis-exporter/values.yaml";
      chart_url = prom_chart "prometheus-redis-exporter";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
  };
}
