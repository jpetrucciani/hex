# Helm Integration

## OpenCost

`hex.k8s.opencost` wraps the [OpenCost chart](https://github.com/opencost/opencost-helm-chart).
Use `version.v2-5-33 { }` to pin chart **2.5.33** (app **1.121.3**), or
`version.latest { }` to follow the first entry in hex's version map. The default
release name and namespace are both `opencost`. The chart does not create the
namespace; ensure it exists before deployment.

[OpenCost's Helm installation](https://opencost.io/docs/installation/helm/)
assumes an existing Prometheus. This wrapper installs no monitoring stack. The
upstream default query endpoint is
`http://prometheus-server.prometheus-system.svc.cluster.local:80`; adapt it to
your existing service. [The runnable example](https://github.com/jpetrucciani/hex/blob/main/examples/opencost.nix)
overrides the release name, namespace, cluster ID and Prometheus service:

<<< ../examples/opencost.nix

Render locally without contacting a cluster:

```sh
nix run .#hex -- --render -t examples/opencost.nix
```

For a Prometheus query endpoint outside the cluster, replace the example's
`prometheus` configuration with:

```nix
prometheus = {
  internal.enabled = false;
  external = {
    enabled = true;
    url = "https://prometheus.example.test/prometheus";
  };
};
```

Configure your existing Prometheus to scrape kubelet/cAdvisor resource usage,
kube-state-metrics (or the compatible metrics emitted by OpenCost), and OpenCost's
`/metrics` endpoint on Service port `http` (9003). Avoid duplicate KSM series;
see the [upstream Prometheus guidance](https://opencost.io/docs/installation/prometheus/)
and [scrape configuration](https://github.com/opencost/opencost/blob/v1.121.3/kubernetes/prometheus/extraScrapeConfigs.yaml).
Setting a query URL alone does not configure these scrape targets.
`valuesAttrs.opencost.metrics.serviceMonitor.enabled = true` optionally emits a
`monitoring.coreos.com/v1` ServiceMonitor. This requires the Prometheus Operator
CRD and a Prometheus instance whose selectors include that ServiceMonitor and
namespace; neither the operator nor CRDs are installed by this chart.

In pinned chart 2.5.33, the defaults create a ServiceAccount with an automounted
API token and cluster-wide read RBAC (`get`, `list`, `watch`) for Kubernetes
inventory; there are no Secret-read or write permissions. The wrapper preserves
cluster-scoped RBAC metadata. The Service is ClusterIP with API/metrics on 9003
and UI on 9090; ingress, HTTPRoute, OpenShift routes, network policies and cloud
cost ingestion are off. No cloud credentials are supplied. Pod and container
security contexts are empty upstream; privileged mode and host access are not
enabled. Review these defaults for your environment before deploying.

Hex explicitly defaults `opencost.mcp.enabled` to `false` because upstream
2.5.33 enables it. All upstream settings remain configurable through
`valuesAttrs`, `values` files and `sets`; for example,
`valuesAttrs.opencost.ui.enabled = false` disables the UI. Consult the
[pinned values](https://github.com/opencost/opencost-helm-chart/blob/opencost-2.5.33/charts/opencost/values.yaml)
when configuring this version. Hex's MCP default values are applied after
`values` files; override them explicitly through `valuesAttrs` or `sets` if needed.

The local `chart_scan_opencost` package uses the standard scanner generator,
pinned from `jpetrucciani/nix`. Refresh the version map with:

```sh
nix run .#chart_scan_opencost -- -u ./hex/hex/k8s/helm/opencost/opencost.json
```
