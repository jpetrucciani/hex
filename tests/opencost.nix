{ yq_assert }:
[
  {
    name = "opencost-defaults";
    suites = [ "charts" ];
    allowMissingSchemas = false;
    spec = "hex.k8s.opencost.version.latest {}";
    expectedDocuments = 6;
    check = ''
      ${yq_assert ''select(.kind == "Deployment") | .metadata.name == "opencost" and .metadata.namespace == "opencost" and .spec.template.spec.serviceAccountName == "opencost"'' "OpenCost defaults or ServiceAccount changed"}
      ${yq_assert ''select(.kind == "Deployment") | .spec.template.spec.containers[0].env[] | select(.name == "MCP_SERVER_ENABLED") | .value == "false"'' "MCP must remain opt-in"}
      ${yq_assert ''select(.kind == "Service") | .spec.type == "ClusterIP" and (.spec.ports | length) == 2 and .spec.ports[0].port == 9003 and .spec.ports[1].port == 9090'' "OpenCost must expose only its internal API and UI by default"}
      ${yq_assert ''select(.kind == "ClusterRole") | .metadata | has("namespace") | not'' "OpenCost ClusterRole must remain cluster-scoped"}
      ${yq_assert ''select(.kind == "ClusterRoleBinding") | .metadata | has("namespace") | not'' "OpenCost ClusterRoleBinding must remain cluster-scoped"}
      ${yq_assert ''select(.kind == "ClusterRole") | [.rules[].verbs[] | select(. != "get" and . != "list" and . != "watch")] | length == 0'' "OpenCost must not gain write permissions"}
      ${yq_assert ''select(.kind == "ClusterRole") | [.rules[].resources[] | select(. == "secrets" or . == "*" or . == "nodes/proxy")] | length == 0'' "OpenCost must not gain Secret or node proxy access"}
      ${yq_assert ''select(.kind == "ClusterRoleBinding") | .roleRef.name == "opencost" and .subjects[0].name == "opencost" and .subjects[0].namespace == "opencost"'' "OpenCost RBAC binding must target its ServiceAccount"}
    '';
  }
  {
    name = "opencost-example";
    suites = [ "charts" ];
    allowMissingSchemas = false;
    spec = ''import ${../examples/opencost.nix} { inherit hex; }'';
    expectedDocuments = 6;
    check = ''
      ${yq_assert ''select(.kind == "Deployment") | .metadata.name == "costs-opencost" and .metadata.namespace == "monitoring" and .metadata.labels."helm.sh/chart" == "opencost-2.5.33"'' "OpenCost example must use its pinned version and custom release/namespace"}
      ${yq_assert ''select(.kind == "Deployment") | .spec.template.spec.containers[0].env[] | select(.name == "PROMETHEUS_SERVER_ENDPOINT") | .value == "http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090"'' "OpenCost must query the existing Prometheus service"}
      ${yq_assert ''select(.kind == "Deployment") | .spec.template.spec.containers[0].env[] | select(.name == "CLUSTER_ID") | .value == "example-cluster"'' "OpenCost must accept values overrides"}
      ${yq_assert ''select(.kind == "ClusterRoleBinding") | .subjects[0].name == "costs-opencost" and .subjects[0].namespace == "monitoring"'' "custom release RBAC must bind the correct ServiceAccount"}
    '';
  }
  {
    name = "opencost-options";
    suites = [ "charts" ];
    spec = ''
      hex.k8s.opencost.version.v2-5-33 {
        namespace = "costs";
        valuesAttrs.opencost = {
          ui.enabled = false;
          prometheus = {
            internal.enabled = false;
            external = { enabled = true; url = "https://prometheus.example.test/prometheus"; };
          };
          metrics.serviceMonitor = { enabled = true; namespace = "monitoring"; };
        };
      }
    '';
    expectedDocuments = 6;
    check = ''
      ${yq_assert ''select(.kind == "Deployment") | .spec.template.spec.containers[0].env[] | select(.name == "PROMETHEUS_SERVER_ENDPOINT") | .value == "https://prometheus.example.test/prometheus"'' "OpenCost must accept an external query endpoint"}
      ${yq_assert ''select(.kind == "ServiceMonitor") | .metadata.namespace == "monitoring" and .spec.namespaceSelector.matchNames[0] == "costs" and .spec.endpoints[0].port == "http" and .spec.endpoints[0].path == "/metrics"'' "ServiceMonitor must retain its own namespace and select the OpenCost metrics endpoint"}
      ${yq_assert ''select(.kind == "Service") | (.spec.ports | length) == 1 and .spec.ports[0].port == 9003'' "upstream UI override must remain configurable"}
    '';
  }
]
