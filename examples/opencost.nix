# Render only: nix run .#hex -- --render -t examples/opencost.nix
# Requires an existing Prometheus with Kubernetes and OpenCost scrape targets.
{ hex, ... }:
hex.k8s.opencost.version.v2-5-33 {
  name = "costs";
  namespace = "monitoring";
  valuesAttrs.opencost = {
    exporter.defaultClusterId = "example-cluster";
    prometheus.internal = {
      enabled = true;
      serviceName = "prometheus-kube-prometheus-prometheus";
      namespaceName = "monitoring";
      port = 9090;
    };
  };
}
