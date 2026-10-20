# [OpenCost](https://github.com/opencost/opencost) measures and allocates Kubernetes and cloud costs.
{ hex, ... }:
let
  opencost = rec {
    docs_meta = {
      notes = [ "See the [OpenCost Helm example](/integration-helm#opencost) for existing Prometheus configuration and chart defaults." ];
    };
    defaults = {
      name = "opencost";
      namespace = "opencost";
      # The pinned upstream chart enables MCP; keep it opt-in in hex.
      valuesAttrs.opencost.mcp.enabled = false;
    };
    values_url = "https://github.com/opencost/opencost-helm-chart/blob/main/charts/opencost/values.yaml";
    chart_url = version: hex.k8s.helm.charts.url.github {
      inherit version;
      org = "opencost";
      repo = "opencost-helm-chart";
      repoName = "opencost";
    };
    # Let Helm preserve cluster-scoped RBAC and any explicit namespace overrides.
    chart = args: (hex.k8s._.chart { inherit defaults chart_url; })
      ({ forceNamespace = false; } // args);
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./opencost.json; };
  };
in
opencost
