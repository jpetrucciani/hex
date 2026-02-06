# This module contains helm charts under the [grafana](https://grafana.com/) observability umbrella. This includes things like [loki](https://github.com/grafana/loki), [mimir](https://github.com/grafana/mimir), and [oncall](https://github.com/grafana/oncall).
{ hex, ... }:
let
  inherit (hex) toYAML toYAMLDoc;
  _chart_url = { name, version, prefix ? "" }: "https://github.com/grafana/helm-charts/releases/download/${prefix}${name}-${version}/${name}-${version}.tgz";
  loki = rec {
    defaults = {
      name = "loki";
      chart_name = "loki";
      namespace = "loki";
    };
    chart = hex.k8s._.chart {
      inherit defaults;
      chart_url = version: _chart_url { inherit version; inherit (defaults) name; prefix = "helm-"; };
    };
    values_url = "https://github.com/grafana/loki/blob/main/production/helm/loki/values.yaml";
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./loki.json; };
    # this agent is deprecated! use alloy instead!
    agent =
      { cluster  # cluster name to report
      , lokiHost ? "loki-write.loki.svc.cluster.local:3100"  # default for a base install of the helm chart
      , name ? "grafana-agent"
      , namespace ? "default"
      , extraConfig ? { }  # extra prometheus config for agent.yaml, as an attrset
      , image ? "${image_base}:${image_tag}"
      , image_base ? "grafana/agent"
      , image_tag ? "v0.42.0"
      , scheme ? "http"
      , lokiPath ? "/loki/api/v1/push"
      , basicAuth ? false
      , basicAuthUser ? ""
      , basicAuthPassword ? ""
      , storageClass ? null
      }:
      let
        sa = {
          apiVersion = "v1";
          kind = "ServiceAccount";
          metadata = {
            inherit name namespace;
          };
        };
        cluster_role = {
          apiVersion = "rbac.authorization.k8s.io/v1";
          kind = "ClusterRole";
          metadata = {
            inherit name;
          };
          rules = [
            {
              apiGroups = [ "" ];
              resources = [
                "nodes"
                "nodes/proxy"
                "services"
                "endpoints"
                "pods"
                "events"
              ];
              verbs = [
                "get"
                "list"
                "watch"
              ];
            }
            {
              nonResourceURLs = [ "/metrics" ];
              verbs = [ "get" ];
            }
          ];
        };
        cluster_role_binding = {
          apiVersion = "rbac.authorization.k8s.io/v1";
          kind = "ClusterRoleBinding";
          metadata = { inherit name; };
          roleRef = {
            apiGroup = "rbac.authorization.k8s.io";
            kind = "ClusterRole";
            inherit name;
          };
          subjects = [
            {
              inherit name namespace;
              kind = "ServiceAccount";
            }
          ];
        };
        service = {
          apiVersion = "v1";
          kind = "Service";
          metadata = {
            labels = { inherit name; };
            inherit name namespace;
          };
          spec = {
            clusterIP = "None";
            ports = [
              {
                name = "grafana-agent-http-metrics";
                port = 80;
                targetPort = 80;
              }
            ];
            selector = {
              inherit name;
            };
          };
        };
        config = {
          apiVersion = "v1";
          data = {
            "agent.yaml" = toYAMLDoc
              ({
                integrations = {
                  eventhandler = {
                    cache_path = "/var/lib/agent/eventhandler.cache";
                    logs_instance = "integrations";
                  };
                };
                logs = {
                  configs = [
                    {
                      clients = [
                        {
                          ${if basicAuth then "basic_auth" else null} = {
                            password = basicAuthPassword;
                            username = basicAuthUser;
                          };
                          external_labels = {
                            inherit cluster;
                            job = "integrations/kubernetes/eventhandler";
                          };
                          url = "${scheme}://${lokiHost}${lokiPath}";
                        }
                      ];
                      name = "integrations";
                      positions = {
                        filename = "/tmp/positions.yaml";
                      };
                      target_config = {
                        sync_period = "10s";
                      };
                    }
                  ];
                };
              } // extraConfig);
          };
          kind = "ConfigMap";
          metadata = {
            inherit name namespace;
          };
        };
        statefulset = {
          apiVersion = "apps/v1";
          kind = "StatefulSet";
          metadata = {
            inherit name namespace;
          };
          spec = {
            replicas = 1;
            selector = {
              matchLabels = {
                inherit name;
              };
            };
            serviceName = name;
            template = {
              metadata = {
                labels = { inherit name; };
              };
              spec = {
                containers = [
                  {
                    inherit image;
                    args = [
                      "-config.expand-env=true"
                      "-config.file=/etc/agent/agent.yaml"
                      "-enable-features=integrations-next"
                      "-server.http.address=0.0.0.0:80"
                    ];
                    env = [
                      {
                        name = "HOSTNAME";
                        valueFrom = {
                          fieldRef = {
                            fieldPath = "spec.nodeName";
                          };
                        };
                      }
                    ];
                    imagePullPolicy = "IfNotPresent";
                    inherit name;
                    ports = [
                      {
                        containerPort = 80;
                        name = "http-metrics";
                      }
                    ];
                    volumeMounts = [
                      {
                        mountPath = "/var/lib/agent";
                        name = "agent-wal";
                      }
                      {
                        mountPath = "/etc/agent";
                        inherit name;
                      }
                    ];
                  }
                ];
                serviceAccountName = "grafana-agent";
                volumes = [
                  {
                    configMap = {
                      inherit name;
                    };
                    inherit name;
                  }
                ];
              };
            };
            updateStrategy = {
              type = "RollingUpdate";
            };
            volumeClaimTemplates = [
              {
                apiVersion = "v1";
                kind = "PersistentVolumeClaim";
                metadata = {
                  name = "agent-wal";
                  inherit namespace;
                };
                spec = {
                  accessModes = [
                    "ReadWriteOnce"
                  ];
                  ${if storageClass != null then "storageClassName" else null} = storageClass;
                  resources = {
                    requests = {
                      storage = "5Gi";
                    };
                  };
                };
              }
            ];
          };
        };
      in
      assert basicAuth -> basicAuthUser != "";
      assert basicAuth -> basicAuthPassword != "";
      builtins.warn "grafana agent is deprecated! use alloy instead!"
        ''
          ${toYAMLDoc config}
          ${toYAMLDoc sa}
          ${toYAMLDoc cluster_role}
          ${toYAMLDoc cluster_role_binding}
          ${toYAMLDoc service}
          ${toYAMLDoc statefulset}
        '';

    # promtail is deprecated! use alloy instead!
    # promtail will tail all the stderr and stdout of logs in the cluster to the specified loki endpoint
    promtail =
      { cluster  # cluster name to report
      , lokiHost ? "loki-write.loki.svc.cluster.local:3100"  # default for a base install of the helm chart
      , name ? "promtail"
      , namespace ? "default"
      , extraConfig ? { } # extra config for promtail.yml, as an attrset
      , scheme ? "http"
      , lokiPath ? "/loki/api/v1/push"
      , basicAuth ? false
      , basicAuthUser ? ""
      , basicAuthPassword ? ""
      }:
      let
        labels = { inherit name; };
        sa = {
          apiVersion = "v1";
          kind = "ServiceAccount";
          metadata = {
            inherit name namespace;
          };
        };
        clusterrolebinding = {
          apiVersion = "rbac.authorization.k8s.io/v1";
          kind = "ClusterRoleBinding";
          metadata = { inherit name; };
          roleRef = {
            apiGroup = "rbac.authorization.k8s.io";
            kind = "ClusterRole";
            inherit name;
          };
          subjects = [
            {
              kind = "ServiceAccount";
              inherit name namespace;
            }
          ];
        };
        clusterrole = {
          apiVersion = "rbac.authorization.k8s.io/v1";
          kind = "ClusterRole";
          metadata = { inherit name; };
          rules = [
            {
              apiGroups = [ "" ];
              resources = [
                "nodes"
                "services"
                "pods"
              ];
              verbs = [
                "get"
                "watch"
                "list"
              ];
            }
          ];
        };
        configmap = {
          apiVersion = "v1";
          data = {
            "promtail.yaml" = toYAML ({
              clients = [
                {
                  ${if basicAuth then "basic_auth" else null} = {
                    password = basicAuthPassword;
                    username = basicAuthUser;
                  };
                  url = "${scheme}://${lokiHost}${lokiPath}";
                }
              ];
              positions = {
                filename = "/tmp/positions.yaml";
              };
              scrape_configs = [
                {
                  job_name = "pod-logs";
                  kubernetes_sd_configs = [
                    {
                      role = "pod";
                    }
                  ];
                  pipeline_stages = [
                    {
                      docker = { };
                    }
                    {
                      static_labels = {
                        inherit cluster;
                      };
                    }
                  ];
                  relabel_configs = [
                    {
                      source_labels = [
                        "__meta_kubernetes_pod_node_name"
                      ];
                      target_label = "__host__";
                    }
                    {
                      action = "labelmap";
                      regex = "__meta_kubernetes_pod_label_(.+)";
                    }
                    {
                      action = "replace";
                      replacement = "$1";
                      separator = "/";
                      source_labels = [
                        "__meta_kubernetes_namespace"
                        "__meta_kubernetes_pod_name"
                      ];
                      target_label = "job";
                    }
                    {
                      action = "replace";
                      source_labels = [
                        "__meta_kubernetes_namespace"
                      ];
                      target_label = "namespace";
                    }
                    {
                      action = "replace";
                      source_labels = [
                        "__meta_kubernetes_pod_name"
                      ];
                      target_label = "pod";
                    }
                    {
                      action = "replace";
                      source_labels = [
                        "__meta_kubernetes_pod_container_name"
                      ];
                      target_label = "container";
                    }
                    {
                      replacement = "/var/log/pods/*$1/*.log";
                      separator = "/";
                      source_labels = [
                        "__meta_kubernetes_pod_uid"
                        "__meta_kubernetes_pod_container_name"
                      ];
                      target_label = "__path__";
                    }
                  ];
                }
              ];
              server = {
                grpc_listen_port = 0;
                http_listen_port = 9080;
              };
              target_config = {
                sync_period = "10s";
              };
            } // extraConfig);
          };
          kind = "ConfigMap";
          metadata = {
            inherit namespace;
            name = "promtail-config";
          };
        };
        daemonset = {
          apiVersion = "apps/v1";
          kind = "DaemonSet";
          metadata = { inherit name namespace; };
          spec = {
            selector = {
              matchLabels = labels;
            };
            template = {
              metadata = {
                inherit labels;
              };
              spec = {
                containers = [
                  {
                    args = [
                      "-config.file=/etc/promtail/promtail.yaml"
                    ];
                    env = [
                      {
                        name = "HOSTNAME";
                        valueFrom = {
                          fieldRef = {
                            fieldPath = "spec.nodeName";
                          };
                        };
                      }
                    ];
                    image = "grafana/promtail";
                    name = "promtail-container";
                    volumeMounts = [
                      {
                        mountPath = "/var/log";
                        name = "logs";
                      }
                      {
                        mountPath = "/etc/promtail";
                        name = "promtail-config";
                      }
                      {
                        mountPath = "/var/lib/docker/containers";
                        name = "varlibdockercontainers";
                        readOnly = true;
                      }
                    ];
                  }
                ];
                serviceAccount = "promtail";
                volumes = [
                  {
                    hostPath = {
                      path = "/var/log";
                    };
                    name = "logs";
                  }
                  {
                    hostPath = {
                      path = "/var/lib/docker/containers";
                    };
                    name = "varlibdockercontainers";
                  }
                  {
                    configMap = {
                      name = "promtail-config";
                    };
                    name = "promtail-config";
                  }
                ];
              };
            };
          };
        };
      in
      assert basicAuth -> basicAuthUser != "";
      assert basicAuth -> basicAuthPassword != "";
      builtins.warn "promtail is deprecated! use alloy instead!"
        ''
          ${toYAMLDoc sa}
          ${toYAMLDoc clusterrole}
          ${toYAMLDoc clusterrolebinding}
          ${toYAMLDoc configmap}
          ${toYAMLDoc daemonset}
        '';
  };
  alloy = rec {
    defaults = {
      name = "alloy";
      namespace = "default";
    };
    chart = hex.k8s._.chart {
      inherit defaults;
      chart_url = version: _chart_url { inherit version; inherit (defaults) name; };
    };
    values = "https://github.com/grafana/alloy/blob/main/operations/helm/charts/alloy/values.yaml";
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./alloy.json; };
  };
  mimir = rec {
    defaults = {
      name = "mimir";
      chart_name = "mimir-distributed";
      namespace = "mimir";
    };
    chart = hex.k8s._.chart {
      inherit defaults;
      chart_url = version: _chart_url { inherit version; name = defaults.chart_name; };
    };
    values_url = "https://github.com/grafana/mimir/blob/main/operations/helm/charts/mimir-distributed/values.yaml";
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./mimir.json; };
  };
  tempo = rec {
    defaults = {
      name = "tempo";
      chart_name = "tempo-distributed";
      namespace = "tempo";
    };
    chart = hex.k8s._.chart {
      inherit defaults;
      chart_url = version: _chart_url { inherit version; name = defaults.chart_name; };
    };
    values = "https://github.com/grafana/helm-charts/blob/main/charts/tempo-distributed/values.yaml";
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./tempo.json; };
  };
  oncall = rec {
    defaults = {
      name = "oncall";
      namespace = "oncall";
    };
    chart = hex.k8s._.chart {
      inherit defaults;
      chart_url = version: _chart_url { inherit version; inherit (defaults) name; };
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v1-15-6;
      v1-15-6 = _v "1.15.6" "1n49svkb1v30pavhr3r13xlin38nmbkshwbc42q6zc6hlcnkhwdp"; # 2025-04-18
      v1-15-2 = _v "1.15.2" "151bsplwa035cr27hig0a8qkfnr0mzq7hz62l92dqgsdk6ppjzha"; # 2025-03-06
      v1-14-4 = _v "1.14.4" "1ij5bjbqkx1gmk9qxz02ilr1397ibl4ppr9nd9w5wihcps96piib"; # 2025-02-14
      v1-13-11 = _v "1.13.11" "14w4nbx4v0s6wh66brl98dkc3h0hlnsq6xz0vrihdgpla1lg495a"; # 2024-12-16
      v1-12-1 = _v "1.12.1" "02kzzlappaaxp753inih3v7s4mwv5h3ps0n6pc55pad0x7myvc2v"; # 2024-11-06
      v1-9-22 = _v "1.9.22" "01r59filgn5zygpp96lw036w6kl295xvyiz8j09pmdwca5vgk5ya"; # 2024-09-04
      v1-9-18 = _v "1.9.18" "0kdjr3h8kc6hvjb74n9ywklgd59jj3i1zxd60xp8hhrc13sab9am"; # 2024-08-29
      v1-8-13 = _v "1.8.13" "1jnvq2zyi4ncqw6l8i4cg1ixqhq16zwzbwbxfy9dqb0ml8ypssz9"; # 2024-08-15
      v1-7-2 = _v "1.7.2" "0xi4i4a0fklri71z2pia0ypj48nxw9nhvh7849yprjjmws35lrr6"; # 2024-06-20
      v1-7-1 = _v "1.7.1" "0fxklg48bvifbfss1xsahybzdz05hapyq2c2rfz91l8nxkrcqs3j"; # 2024-06-13
      v1-6-2 = _v "1.6.2" "1dzvv6wxrzxgv7ff25g1p5k2j3f3i1h4kvb35iwf8gw1lk4y3v12"; # 2024-06-05
      v1-5-5 = _v "1.5.5" "1jv6d8h7px45f0dab9ws92f4vjnyqq1b10k657rliks1kv93nqxs"; # 2024-06-03
      v1-4-7 = _v "1.4.7" "0a8ij66rcps0p3z8p69nl1y5742fh5a19slqfzl28kpzdikmx629"; # 2024-05-13
      v1-3-118 = _v "1.3.118" "0ywz3v2q9iy5z24rad3m9570hc3jwsfr1yzj0ba3m8fq4zyvb7k6"; # 2024-04-11
      v1-3-113 = _v "1.3.113" "0yqlsfhmcabppcczad6hdlaav2nxi9z9i4nn51h1rdh6w7g6xc2s"; # 2024-03-21
      v1-3-45 = _v "1.3.45" "1xrrryq5bvvbpxplpnwqn6yr0c1sp4k2idib5hybky8sczyfjjyn";
    };
  };
in
{ inherit alloy loki mimir tempo oncall; }
