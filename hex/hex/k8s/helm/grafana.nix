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
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v6-45-1;
      v6-45-1 = _v "6.45.1" "03w9bakgl8nz73ay04j52ysl44x4s1g1cc5ra5kalvp0np6ywj8y"; # 2025-10-30
      v6-45-0 = _v "6.45.0" "16ir0xkim2lb6s39vgdglvf1y20iipsq35l3hqmrcgx3x3lba4m1"; # 2025-10-30
      v6-44-0 = _v "6.44.0" "0la4az5ky3mmwwxb3aj2qh3ip1x7hha9hx8sic5bcn8q4pwgdj9l"; # 2025-10-23
      v6-43-0 = _v "6.43.0" "1982mpfvspn801p7s95k4h99c6d074b84g87sg7bm73427m3pr7z"; # 2025-10-15
      v6-42-0 = _v "6.42.0" "014vvryd1m9i09ya3ffqkikakr410gh94jj1bca7lpmrwh5hccqr"; # 2025-10-02
      v6-41-1 = _v "6.41.1" "0xk3h6hvki1k8gkkvshzida4s29c7rw69s4jnx83pxp7af9xz141"; # 2025-09-25
      v6-41-0 = _v "6.41.0" "1k8afvd5vimqfwc9j5fkikyw3cdzc8kq8cs7sajn0nmzb9skngmm"; # 2025-09-24
      v6-40-0 = _v "6.40.0" "1qisyr9gxbf4j3vbic329fyvqy4bw8kcgr91515gvadl8lq12q40"; # 2025-09-09
      v6-39-0 = _v "6.39.0" "1yc40831z46ki9pwjj088w9x5bw7hkzf3f1hxzzv4xhhnj4r9569"; # 2025-09-04
      v6-38-0 = _v "6.38.0" "18212vxgydha9qdc5jaalgmsb868n5wmvg0ymjbjd5hbv2nmz065"; # 2025-08-27
      v6-37-0 = _v "6.37.0" "1jjw2k0s3kaplgl20rdbxyky8xz0mwb84dwb1dd9adrda0jhbhcg"; # 2025-08-21
      v6-36-1 = _v "6.36.1" "0sc1w5hgwbg7hh0jlq3s4qxxavhfr0qz7z1qmr5qxwg3nz1accnc"; # 2025-08-15
      v6-36-0 = _v "6.36.0" "0ii6ylnllp6qqa20fyl6x0i3mvxifvbqr6gjpq61bxv58s0rhs1z"; # 2025-08-14
      v6-35-1 = _v "6.35.1" "0qx0qia1xmk98gjh0dci6wp9sav1arvhdscj0s3pvrrzzf0lvwk3"; # 2025-08-06
      v6-35-0 = _v "6.35.0" "15am0fk8an2zyscigvixhl237ipxcz1cx348arfx5083dwljhvqg"; # 2025-08-05
      v6-34-0 = _v "6.34.0" "0hzxdblvx9pf0xqs4nq46ajxcw7kkggbsjd4zx4v72mcyknbhgl7"; # 2025-07-29
      v6-33-0 = _v "6.33.0" "0k04ar81g3w1x75gss9c9lb7p59vikj5bhmvrww2iz6ybwax961c"; # 2025-07-23
      v6-32-0 = _v "6.32.0" "0sz8pf976iiqyagzsy36fcj91aw7p70vf3lnmmixfn078n7qlbiz"; # 2025-07-15
      v6-31-0 = _v "6.31.0" "07g6h2kr6a4jqfnfc6ag4lhi3ckh2bfdhpmb80b7l2ygz5lmnap2"; # 2025-07-08
      v6-30-1 = _v "6.30.1" "1wbdhs740q9h94v4b056gxk26gb9y4vnv073g9lnhrji1gzmmpg7"; # 2025-05-28
      v6-30-0 = _v "6.30.0" "0n4s9biqva4lwskywfmagr79kyqdr7lfrbkd8fspz04dz1f5yxqb"; # 2025-05-21
      v6-29-0 = _v "6.29.0" "1cppwhqdl0phhh33h1a5wlk0xwpk1dx60ga6vanc16fixzdr367s"; # 2025-03-26
      v6-28-0 = _v "6.28.0" "0fdf99b5jn6qg28z1qrf821b4m7fwkprzhrgx5vjwjgc8637771g"; # 2025-03-10
      v6-27-0 = _v "6.27.0" "179xi3jmjg1qsmb7jddd2rd0974iw7karmc0bnkkngqnp1r2c1qw"; # 2025-02-14
      v6-16-0 = _v "6.16.0" "0lhy43syl9zhddm9jfjzbbc0z561lsla4q4h4rspgx8xkzv9qz4i"; # 2024-09-30
      v6-15-0 = _v "6.15.0" "184nx1fkqb4dypy713n110yfar3mhv2962njndd1f779pmgwxmx6"; # 2024-09-26
      v6-12-0 = _v "6.12.0" "1fm61h3xbawih946pmqr41md65ypwh03mknpnvjiqnch90hl8jv1"; # 2024-09-03
      v6-11-0 = _v "6.11.0" "1gq1wjx6x7qjrqyy6jdg95y45kgnz0znjpvi2pig3vbd7fd66sj7"; # 2024-09-02
      v6-10-2 = _v "6.10.2" "0rbkkkjk58ssi7a6zfvh9n0xbra12is2qca6pvg5lm684fm7kvnh"; # 2024-08-29
      v6-9-0 = _v "6.9.0" "0qznl7jcmdqf1dvwvvpk9mdqwr2pha01d8xvvxwx8rsc3n6ipsji"; # 2024-08-07
      v6-8-0 = _v "6.8.0" "1f4w10y86d01nfx771rxig5fkzyi35gyvsjinbhmb06drwz09kql"; # 2024-08-05
      v6-7-4 = _v "6.7.4" "1nbdrwvpdmj84h08d7ghxd9mss5gz26kkmmb35axjn5zimq0ck7z"; # 2024-08-05
      v6-6-6 = _v "6.6.6" "0s03v0gbjpn34k1jb2pq3dp47w0j7pynngxc4scqmk5b0v702cz2"; # 2024-07-11
      v6-6-5 = _v "6.6.5" "1mj0psnsswd04vaskxc6xqq0q0n5lir6j192ca1rgk3l8dlgyq9x"; # 2024-07-03
      v6-5-2 = _v "6.5.2" "00ydqpmgdhbclnian59nwlf4yjq4lqwmsfh0a7qm9267mxd37crc"; # 2024-05-10
      v6-4-2 = _v "6.4.2" "1yfk8m9yabyzv6lijymgf025069mbiswd4d55lldavzcqq96s5yk"; # 2024-04-30
      v6-3-4 = _v "6.3.4" "1130nycffid25rbnlgffsihhjiz75356iii0lmhkzrb8nlca8q7d"; # 2024-04-22
      v6-0-0 = _v "6.0.0" "08hy2fwr6rlqc0cf6g815fly45nmf1kv3ngfgmy4k2jyf5rd8z50"; # 2024-04-08
      v5-47-2 = _v "5.47.2" "0wax65hy9gc56gch0ypgm10a9qya5r6ygnnv3klna1a94nf32d4n"; # 2024-03-28
      v5-47-1 = _v "5.47.1" "171iwpniwc7q35vd5vgz9jzd8j24az4f3gsxgdlp1a4r5y5kxjm9"; # 2024-03-22
      v5-44-4 = _v "5.44.4" "124fms4hpqyr40a9jb5bvh48m5dvqi7m7xyq234c7d2jbqm0w201"; # 2024-03-18
      v5-43-7 = _v "5.43.7" "1n8mbv198kjx4drbvv6alh3l2vr86spvv3zik99ppajfpi8pv0rv"; # 2024-03-14
      v5-42-3 = _v "5.42.3" "0qkbivgpwbx7ffwh7szs725qhvla2bh1h66ja5zdnyry5wagcz8k"; # 2024-02-14
    };
    # this agent is useful for pushing k8s logs into loki
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
      ''
        ${toYAMLDoc config}
        ${toYAMLDoc sa}
        ${toYAMLDoc cluster_role}
        ${toYAMLDoc cluster_role_binding}
        ${toYAMLDoc service}
        ${toYAMLDoc statefulset}
      '';

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
    # values: https://github.com/grafana/alloy/blob/main/operations/helm/charts/alloy/values.yaml
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v1-4-0;
      v1-4-0 = _v "1.4.0" "1p5sxllwghn5h6jghg74icrjnynpkd2iw6yhlrg2cmac3v1zwdw9"; # 2025-10-27
      v1-3-1 = _v "1.3.1" "0rxrc7f3kdx1r6v0xfnc4x2dx92zjifip02sbgmxgnjbnf26l4wn"; # 2025-10-14
      v1-3-0 = _v "1.3.0" "064pnbv52smfvm0fllvkxza2z6jjzg0ckqp2080v9gn46rbx633l"; # 2025-09-30
      v1-2-1 = _v "1.2.1" "1sbqb68139dz9iswnvfi147aslmqiw6bgdrl5qk3dp52i3kvzni3"; # 2025-08-07
      v1-2-0 = _v "1.2.0" "1i3749xa6jhliqr2nnkb9sf9ywqd27w0jifi3bndnz2w53i7qbk1"; # 2025-07-18
      v1-1-2 = _v "1.1.2" "1gcgsn4wbczhfjqb3sqbxg0az1cgnqkd3b2j1ix8346fyd7vkvil"; # 2025-06-27
      v1-1-1 = _v "1.1.1" "0pjirqpc4frggs0zicm6grwiv26dv6dqyn600nsakw79jmkzvll8"; # 2025-06-05
    };
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
    # values: https://github.com/grafana/mimir/blob/main/operations/helm/charts/mimir-distributed/values.yaml
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v5-8-0;
      v5-8-0 = _v "5.8.0" "15dn9dxxf2rx6g2wgq4h0fhbhvvggcdzkn2agyrxp4xi6hrj79ls"; # 2025-08-20
      v5-7-0 = _v "5.7.0" "0da9pjrs5b43ssn0yhig2cq14lzdaagrm2758zj2n26z3r8xj5m9"; # 2025-04-10
      v5-6-1 = _v "5.6.1" "0jqwqpxbc9l89d29bk8lrrlca6fcypxvg77353fvh9rjpg7yqjbj"; # 2025-04-16
      v5-6-0 = _v "5.6.0" "1y3vcs18yh08ncfdrj4p3jsbfm2r5li4n4c7izdpgiq7pfcfk7zj"; # 2025-01-16
      v5-5-1 = _v "5.5.1" "1a66zb2sdgx5c2g8kq6yi6wl04xnhcnx4kcpib9j4ba8bg3hqfr7"; # 2024-10-21
      v5-4-1 = _v "5.4.1" "0046ylyjjdjafrpbfa4k2i7gk1dk03dqp7vbhb0vqv30nqycdp6x"; # 2024-08-15
      v5-3-1 = _v "5.3.1" "1h29kf5y0w7pfzc2h4a73ivls7hmcxlqcjmzypz12maa6chz0izy"; # 2024-09-09
      v5-2-3 = _v "5.2.3" "0d8snrg661fwm2p621h0wf8l8aygyc492xkdc5yxl89i33d29nbx"; # 2024-03-15
      v5-1-2 = _v "5.1.2" "0frz4fs0za92flb81cgpxhjrkrsmypykz6ynn5j4z1vafqs4ckhq";
    };
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
    # values: https://github.com/grafana/helm-charts/blob/main/charts/tempo-distributed/values.yaml
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v1-52-4;
      v1-52-5 = _v "1.52.5" "1xgdlsbz9gid94cb96wrd643g7pzvdn7sq1fb42qhz1qc5xr712m"; # 2025-10-31
      v1-52-4 = _v "1.52.4" "16a0x73qnabgc3ad6s8z8xdh6qb0km0dyv62cram1gz22vdkpkiq"; # 2025-10-29
      v1-52-3 = _v "1.52.3" "1bjy0y6s3g6chsvx8c0k42w2scx73rcwadfkp38x908bxrp1djc7"; # 2025-10-28
      v1-52-2 = _v "1.52.2" "1wj4imgdprhq8fx4bzs6a0a9s4q08mlxq2v9nyqcgjs0f31rhh6f"; # 2025-10-27
      v1-52-1 = _v "1.52.1" "0gmdxrlarvrg9j9j2gc9s4j8zndn1b0i6x1khnhgf7wbkp0ls21l"; # 2025-10-27
      v1-52-0 = _v "1.52.0" "15rsjchmzj6hcvdbjhbgj01xlrjkh5xrprjn9pssq5rf8r0p7bnb"; # 2025-10-27
      v1-51-2 = _v "1.51.2" "1l3r5zn518ayx79li9kcavz161y343cjdaxdb4h2xagh903vzwvw"; # 2025-10-27
      v1-51-1 = _v "1.51.1" "1ni43wffwm8pdsmd7pxxl9r2y19a3pp6ks0d68c25f6gw2fqz7mi"; # 2025-10-26
      v1-51-0 = _v "1.51.0" "18bnqbknpx7f7ynia1cdbyvm4az4g5s6kzfhxqnlaysixlzg3jjj"; # 2025-10-26
      v1-50-0 = _v "1.50.0" "1k60azh6zkwkj1yy00hkbw3jigcwbns93drv9jxif1zs18gscs9b"; # 2025-10-25
      v1-49-0 = _v "1.49.0" "1kpzynysi05mjrzg7ss3jqmafx3mp7ng9y7jfycf7f2hjmkplb7x"; # 2025-10-25
      v1-48-1 = _v "1.48.1" "0m15mvfbdsyq1fzsp4g8jhs8jrczxmvfi04q879v3id3l8sf9jya"; # 2025-10-15
      v1-48-0 = _v "1.48.0" "1zjbpy5k9g184snijkj9s5ph09c312563js5zqi1ww9jgh9y6mm1"; # 2025-09-18
      v1-47-4 = _v "1.47.4" "18kq76fcdlw5xkg7i0h4ncz1ypj44isjg1p28mrmn2pwdnzfikvj"; # 2025-09-17
      v1-47-3 = _v "1.47.3" "1yghqj1ng39anmcb8w441xm8i3r479nrw15yy80yrwj6cb85p2iw"; # 2025-09-12
      v1-47-2 = _v "1.47.2" "0drq0kb8glpfp8dk313yf8ky8kh5xnsb82awdvh2rkpk5g0psxpr"; # 2025-09-11
      v1-47-1 = _v "1.47.1" "0c5ri85l3jqrncw2jvd5q6rsmhh7353n5ixxwk8x79kg3skp5zll"; # 2025-08-29
      v1-47-0 = _v "1.47.0" "0vqzrjysvc64ys2bjl6dyxw21hhy3f4hiz65lxnqwq3lyi2kr292"; # 2025-08-26
      v1-46-5 = _v "1.46.5" "0r0m2wnf3nrhrxdc4q191p7m7p89r7jcglb3w69v1m1h4k8a2wqs"; # 2025-08-26
      v1-46-4 = _v "1.46.4" "0w5w735f7kcivzlx0wli4h8afg9x105725hdkbs61wqp96p8xik9"; # 2025-08-18
      v1-46-3 = _v "1.46.3" "1wq6gkw7fqs89p4mcf5pxyzyyrjp3r9wiax5f8adpgs9hp7y6sxp"; # 2025-08-07
      v1-46-2 = _v "1.46.2" "113rqn2fm7vrwfapxaizf0riqf48c8mv85wxhn6ly0hiyabswgcw"; # 2025-07-31
      v1-46-1 = _v "1.46.1" "1zndllxvmwln5r1da7mmirhzzx01a6y75vw11axj3h7x7c1ygrj9"; # 2025-07-29
      v1-46-0 = _v "1.46.0" "1il5wqwgknmk1xcyakq55hpx6681lcdqgxyzgr3ici34j27n4zsh"; # 2025-07-19
      v1-45-0 = _v "1.45.0" "0bw7lvpnkmhk9a2fmlbx1jkrk2dn3yr791v9f5n4003i42gc1mk6"; # 2025-07-11
      v1-44-1 = _v "1.44.1" "1zcj76vw0vz5jj05pp2vdn54pfp3sidn1d8dx8887scylzl057j6"; # 2025-07-09
      v1-44-0 = _v "1.44.0" "0kclap1kwar52qw3m0z7sr5hvwhngv4xcwpg587g24canpicbzsl"; # 2025-07-08
      v1-43-0 = _v "1.43.0" "0cr2i7yh72z5j8awm0xrd2bp4wkj6sj48d935bw4xg3gd34l3kjr"; # 2025-07-04
      v1-42-3 = _v "1.42.3" "0s8q8m0nvb1crh6zmqdspfa9x5659jpwsghf6wpxpqn0s4gl7gr3"; # 2025-06-24
      v1-42-2 = _v "1.42.2" "16gljcvzcp691wd1m9j91w2x6z54pcc8j93aa1l1277zni38zgg3"; # 2025-06-17
      v1-42-1 = _v "1.42.1" "0ccljvrsayiblbxq4v07qjyhh46bd56bb545amvhd5lzk4bjksq5"; # 2025-06-14
      v1-42-0 = _v "1.42.0" "1h0lqd2ld1x896igkb79qfp5r051xi37chn8p0k9dp1sfzxy96x8"; # 2025-06-11
      v1-38-2 = _v "1.38.2" "1zccjg9yk3nwpj03ai3l6j1424kcmn0fmvbf6b7lk39bcz8m8l6x"; # 2025-04-21
      v1-38-1 = _v "1.38.1" "1bq75ymrrvdy7plm55k3pl6s3nym8p2aaxz82akvybb8vdh2dcak"; # 2025-04-17
      v1-37-0 = _v "1.37.0" "1716d7jjlyl9f9fhp9xf77m8jrg563w46jl0llnqgz2x8rknypa5"; # 2025-04-14
      v1-36-0 = _v "1.36.0" "052gkcg5fnxdl62ma18a8x2iw14csg744g2pkx1l8372ap4fqb45"; # 2025-04-14
      v1-35-0 = _v "1.35.0" "0iicga1k2jvy1zir86bxbrj47hx4j6z26r9jlwdg52lhssc2j64n"; # 2025-04-09
      v1-34-0 = _v "1.34.0" "0a61vi1ayw0hfznkav09i8gy1s27h22pyxccv312yzpyglqgk3bw"; # 2025-04-07
      v1-33-0 = _v "1.33.0" "0d281s60y6s7rkszg58kpjg5pz9hmv105bsg54jbcrn9qkc75pb9"; # 2025-03-24
      v1-32-7 = _v "1.32.7" "1qpxwwkjaljbjbbbhxzjr3ml4jg32f178p79837251h4rvh13azq"; # 2025-03-14
    };
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
