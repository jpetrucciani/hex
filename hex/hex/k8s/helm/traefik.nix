# [Traefik](https://github.com/traefik/traefik-helm-chart) is a modern HTTP reverse proxy and load balancer made to deploy microservices with ease.
{ hex, pkgs, ... }:
let
  inherit (hex) toYAML toYAMLDoc ifNotEmptyList;

  traefik = rec {
    defaults = {
      name = "traefik";
      namespace = "traefik";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v39-0-0;
      v39-0-0 = _v "39.0.0" "17hxlkf8wzwxlq5fbs7syxkg546jqm2klc7q2fh8c6lwfz6pq8is"; # 2026-01-23
      v38-0-2 = _v "38.0.2" "19zfipy944ak2imzslxg46w66j56g6l9zpjcx804iadaz6k3q4l0"; # 2026-01-08
      v38-0-1 = _v "38.0.1" "1jv1wkmx8dxagakvzs87cm19zv9m16j8dk76a6abqaimyvxxmbms"; # 2025-12-19
      v38-0-0 = _v "38.0.0" "0ziqk2ghfv7y0c8728pmi3nhm1ssma2xgzc38mqk233kmzzkk68k"; # 2025-12-18
      v37-4-0 = _v "37.4.0" "1lhnqrj1kg9hwdx2m2k1vkx24ik8xf0rm4y4v4pm5blhpnvf8236"; # 2025-11-21
      v37-3-0 = _v "37.3.0" "15lj9lrw4i77n7yciabdshiqaf0ds7qijdrb83sh7dvk90wsrxpd"; # 2025-11-10
      v37-2-0 = _v "37.2.0" "0l9z6q76q7fl16nkfhmz8jb300fmqcc0y472iar63ngc9c3cgfmc"; # 2025-10-22
      v37-1-2 = _v "37.1.2" "07z9zd83rap8bxqjm2wycy38yfl34p049qwq65s6i398rl13pcxp"; # 2025-10-03
      v37-1-1 = _v "37.1.1" "120mvmscnwz13hqawp7yy4z501mjzys9y1b2xvafbxqjzk1ykf47"; # 2025-09-10
      v37-1-0 = _v "37.1.0" "02x5qpbdl6s1d08ljqlqls2rwb7qbqwg5lhzqssbrrqmr19n8f3w"; # 2025-09-03
      v37-0-0 = _v "37.0.0" "09l6pdmiaa6axb74rgvwf5wbzgzvib7f708agdw678054pdg6fjj"; # 2025-07-30
      v36-3-0 = _v "36.3.0" "03rsjd0ckq2agsj48f3pkmx50i5m8a1qrh2r5xrzz1x97029q4n3"; # 2025-07-01
      v36-2-0 = _v "36.2.0" "1m5sg2jwg3pyxv5fqfcj1kha6mqr18m28h6fzd59ngvh1id2mss2"; # 2025-06-24
      v36-1-0 = _v "36.1.0" "17ksciaqq7cz0k9v39cr665ppv0p3jf4kxm6gllzaidp753r0l1n"; # 2025-06-11
      v36-0-0 = _v "36.0.0" "1cb1ss47awhwqqcgzqyxgvzw65j6zaz0kxygvspnvr1jjvd1m97k"; # 2025-06-06
      v35-4-0 = _v "35.4.0" "0zphmr151l6yyrn9kl61j6lqxa2543i6s7diq5bkr6xr0afn6pnf"; # 2025-05-23
      v35-3-0 = _v "35.3.0" "0rd3n2xqfs9nfza274wx9zzmdaiapmbdnfpp9vnrn7d9l8ha9q73"; # 2025-05-19
      v35-2-0 = _v "35.2.0" "0gf8xddr1fmphn6lyvvjnmqfa8ax2kc6dxcjp18vi140jbr9i80k"; # 2025-04-29
      v35-1-0 = _v "35.1.0" "06wm8zvj8gxmrq488sldhhdbhkkqd0h29bdp9xh819i04vg5y5c3"; # 2025-04-25
      v35-0-1 = _v "35.0.1" "08mils23q98yybj6vmjy7r93armxy2161z004bb5fxadk1zckmk2"; # 2025-04-18
      v34-5-0 = _v "34.5.0" "14w9d0wwjagfadv4bxcd07jpaja0yrv3hm9nspgnnfcl5dqkr482"; # 2025-03-31
      v34-4-1 = _v "34.4.1" "0zj3xa6abakn88aqq17nirdgsnsh3w2kvn1fvfr698m0r0zycszg"; # 2025-03-04
      v34-3-0 = _v "34.3.0" "1rk2z1jl97xbg1kpzpgj2gj617x8m4fxp3gwj3n1k75aglkdc5v1"; # 2025-02-07
      v34-2-0 = _v "34.2.0" "0krna4xnn0xixjy8k22hr724rghiqrms171gmifjnjhz5fljvmvj"; # 2025-01-28
      v34-1-0 = _v "34.1.0" "0g0adca9r69mxdrzpgfwvqf4qr628fa5c720nswmz0ypdja863kp"; # 2025-01-15
      v33-2-1 = _v "33.2.1" "068vg54rxc60is2awc4js8k91fp49lzv56fy5zwyjybkpc77n9s5"; # 2024-12-13
      v33-1-0 = _v "33.1.0" "1q4482jaf30ksf4myc01g1c7hs4982m37fwm8dy69xa9i6nn95n5"; # 2024-12-02
      v33-0-0 = _v "33.0.0" "1x2qfli1rslkszh77axhcppkh07jsr9b0gk1z2shjdbfkd8k98ir"; # 2024-10-30
      v32-1-1 = _v "32.1.1" "1i9cyy6s6jbv8bhd5gncp6lnd78iqzvr0kmarxs52gf78v7rb0nb"; # 2024-10-11
      v32-0-0 = _v "32.0.0" "18agkj3pn5wy2qghfpaj6wvrq9sg55ignp2cqm820kdxjkvfag7n"; # 2024-09-27
      v31-1-1 = _v "31.1.1" "1jidj68wwa93jz9rwx682fxdh6fp4rmjg83m7xbjfqcv3sw1ma6q"; # 2024-09-20
      v31-0-0 = _v "31.0.0" "1xn9iyr527aiwm1nqa7q3gw2gi9p0mnbh9yf2x5jj10kkpvn667r"; # 2024-09-03
      v30-1-0 = _v "30.1.0" "1s5mrly25rs9hpcb5wzc707qsswihdkp8zz5m3c9yl9cnn2whhw2"; # 2024-08-16
      v29-0-1 = _v "29.0.1" "1d1nb55jmfaks0pqga9yyy920f3pnk6909hlagjwanqwvzxq2zn4"; # 2024-07-09
      v28-3-0 = _v "28.3.0" "1nahyic3gwcgmlh5c4k0wbd3bdraggkp0c51kc75yq192hfkn6n1"; # 2024-06-14
      v27-0-2 = _v "27.0.2" "1mfbyh1ihknkxb1nmasikz7cy6vqbw8741hqdxmh8p1myvldk59k"; # 2024-04-12
      v26-1-0 = _v "26.1.0" "0cmmfx908dli28l36dx38mmw67hajzxymm5fchgs8cfry6gkg4jl"; # 2024-02-19
      v25-0-0 = _v "25.0.0" "0lwix9b6yr7mnlyljqn3530qn8r9i8vazazs00xiccvs82fhmbxr"; # 2023-10-23
      v24-0-0 = _v "24.0.0" "0az08cmyw3h2xh6yhlfp8aw3mrvfz1wv4jg1zqk52zbsjqzczk0l"; # 2023-08-10
      v23-2-0 = _v "23.2.0" "173ncgqi863nbvqvrjfrg9q0ilahswgcyznaiznhxbrxcjisjwqi"; # 2023-07-27
      v22-3-0 = _v "22.3.0" "0x9i5fkz2b00a3zhy9r2501df92wk878spqqplwiq11xn1wl4bxb";
      v21-2-1 = _v "21.2.1" "0inbl2n0yg0r2gnj4hqhbwk0y2fixa2z74lvifff41z2qz8bzm0k";
      v20-8-0 = _v "20.8.0" "1fqyhh55b8l56yq5372g2s4m1kwggh0xln77s1yckdy9pbfgiw78";
      v19-0-4 = _v "19.0.4" "1j0fgr2jmi8p2zxf7k8764lidmw96vqcy5y821hlr66a8l1cp1iy";
      v12-0-7 = _v "12.0.7" "1hy7ikx2zcwyh8904h792f63mz689bxnwqps4wxsbmw626p3wz8p";
      v10-33-0 = _v "10.33.0" "02692bgy5g1p7v9fdclb2fmxxv364kv7xbw2b1z5c2r1wj271g6k";
    };
    index_url = "https://traefik.github.io/charts/index.yaml";
    chart_url = version: "https://traefik.github.io/charts/traefik/traefik-${version}.tgz";
    chart =
      { name ? "traefik${if internal then "-internal" else ""}"
      , namespace ? defaults.namespace
      , sets ? [ ]
      , version ? defaults.version
      , sha256 ? defaults.sha256
      , forceNamespace ? true
      , extraFlags ? [ "--create-namespace" ]
      , internal ? false
      , sortYaml ? false
      , logLevel ? "INFO"
      , valuesAttrs ? null
        # other options
      , replicas ? 3
      , exposeTraefik ? false
      , portTraefik ? 9000
      , exposeHttp ? true
      , portHttp ? 8000
      , exposeHttps ? true
      , portHttps ? 8443
      , exposeMetrics ? false
      , portMetrics ? 9100
      , allowExternalNameServices ? false
      , extraPorts ? { }
      , extraValues ? { }
      , additionalArguments ? [ ]
      }:
      let
        pre27 = (builtins.compareVersions version "27.0.0") == -1;
        proto = {
          tcp = "TCP";
        };
        internalAnnotations =
          if internal then {
            service = {
              annotations = {
                "cloud.google.com/load-balancer-type" = "Internal";
                "service.beta.kubernetes.io/aws-load-balancer-internal" = "true";
                "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internal";
              } // hex.annotations;
            };
          } else {
            service = {
              annotations = {
                "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing";
              } // hex.annotations;
            };
          };
        values = {
          additionalArguments = [
            "--log.level=${logLevel}"
            "--ping"
            "--metrics.prometheus"
            "--serversTransport.insecureSkipVerify=true"
            "--entrypoints.web.forwardedHeaders.insecure"
          ] ++ (if exposeHttps then [
            "--entrypoints.websecure.http.tls"
            "--entrypoints.web.http.redirections.entryPoint.to=websecure"
            "--entrypoints.web.http.redirections.entryPoint.scheme=https"
            "--entrypoints.web.http.redirections.entrypoint.permanent=true"
            "--entrypoints.web.http.redirections.entryPoint.to=:443"
          ] else [ ]) ++ (if allowExternalNameServices then [
            "--providers.kubernetescrd.allowexternalnameservices=true"
            "--providers.kubernetesingress.allowexternalnameservices=true"
          ] else [ ]) ++ additionalArguments;
          deployment = {
            inherit replicas;
          };
          globalArguments = [ ];
          ports = {
            traefik = {
              exposedPort = portTraefik;
              protocol = proto.tcp;
            } // (if pre27 then { expose = exposeTraefik; } else { expose.default = exposeTraefik; });
            web = {
              exposedPort = portHttp;
              port = 8000;
              protocol = proto.tcp;
              # redirectTo = "websecure";
            } // (if pre27 then { expose = exposeHttp; } else { expose.default = exposeHttp; });
            websecure = {
              exposedPort = portHttps;
              port = 8443;
              protocol = proto.tcp;
            } // (if pre27 then { expose = exposeHttps; } else { expose.default = exposeHttps; });
            metrics = {
              expose = exposeMetrics;
              exposedPort = portMetrics;
              port = 9100;
              protocol = proto.tcp;
            } // (if pre27 then { expose = exposeMetrics; } else { expose.default = exposeMetrics; });
          } // extraPorts;
          providers = {
            kubernetesCRD = {
              inherit allowExternalNameServices;
              allowCrossNamespace = true;
              ingressClass = name;
            };
          };
          tlsOptions = {
            default = {
              minVersion = "VersionTLS12";
              sniStrict = true;
            };
            mintls13 = {
              minVersion = "VersionTLS13";
            };
          };
        } // internalAnnotations;
        values_file = pkgs.writeTextFile {
          name = "traefik-values.yaml";
          text = toYAML (values // extraValues);
        };
      in
      hex.k8s.helm.build {
        inherit name namespace sets version sha256 extraFlags forceNamespace sortYaml;
        url = chart_url version;
        values = [ values_file ] ++ (if valuesAttrs != null then [ (hex.valuesFile valuesAttrs) ] else [ ]);
      };

    # middlewares https://doc.traefik.io/traefik/middlewares/http/overview/
    middleware = rec {
      build = args: toYAMLDoc (setup args);
      setup =
        { name
        , spec
        , kind ? "Middleware"
        , pre23 ? false
        , apiVersion ? if pre23 then "traefik.containo.us/v1alpha1" else "traefik.io/v1alpha1"
        , extraSpec ? { }
        }: {
          inherit kind apiVersion spec;
          metadata = {
            inherit name;
          };
        } // extraSpec;
      _ = {
        add_prefix = { prefix, name ? "add-prefix", extraSpec ? { } }: build {
          inherit name extraSpec;
          spec = {
            addPrefix = {
              inherit prefix;
            };
          };
        };
        compress = { name ? "compress", extraSpec ? { } }: build {
          inherit name extraSpec;
          spec = {
            compress = { };
          };
        };
        default_index = { name ? "default-index", extraSpec ? { } }: build {
          inherit name extraSpec;
          spec = {
            replacePathRegex = {
              regex = "^/$";
              replacement = "/index.html";
            };
          };
        };
        ip_allowlist = { ips, name ? "ip-allowlist", extraSpec ? { } }: build {
          inherit name extraSpec;
          spec = {
            ipAllowList.sourceRange = ips;
          };
        };
        ip_whitelist = { ips, name ? "ip-whitelist", extraSpec ? { } }: build {
          inherit name extraSpec;
          spec = {
            ipWhiteList.sourceRange = ips;
          };
        };
        strip_prefix = { prefixes, name ? "strip-prefix", extraSpec ? { } }: build {
          inherit name extraSpec;
          spec = {
            stripPrefix = {
              inherit prefixes;
            };
          };
        };
      };
    };

    # ingressroute https://doc.traefik.io/traefik/v2.2/routing/providers/kubernetes-crd/#kind-ingressroute
    ingress_route = rec {
      constants = { };
      build = args: toYAMLDoc (setup args);
      setup =
        { name
        , domain
        , regex ? false
        , port ? 80
        , namespace ? "default"
        , service ? name
        , serviceScheme ? if port == 443 then "https" else "http"
        , extraService ? { }
        , extraServices ? [ ]
        , internal ? true
        , secretName ? ""
        , labels ? [ ]
        , middlewares ? [ ]
        , extraRule ? { }
        , extraRoutes ? [ ]
        , extraSpec ? { }
        , ingressRouteNamespace ? "default"
        , pre23 ? false
        , apiVersion ? if pre23 then "traefik.containo.us/v1alpha1" else "traefik.io/v1alpha1"
        }:
        let
          secure = (builtins.stringLength secretName) > 0;
          entrypoint = if secure then "websecure" else "web";
          tlsOptions =
            if secure then {
              tls = {
                inherit secretName;
              };
            } else { };
          # route = {kind ? "Rule", match ? "Host(`${host}`)", host ? ""}: {};
        in
        {
          inherit apiVersion;
          kind = "IngressRoute";
          metadata = {
            inherit name;
            namespace = ingressRouteNamespace;
            annotations = {
              "kubernetes.io/ingress.class" = if internal then "traefik-internal" else "traefik";
            } // hex.annotations;
            ${ifNotEmptyList labels "labels"} = labels;
          };
          spec = {
            entryPoints = [ entrypoint ];
            routes = [
              ({
                ${ifNotEmptyList middlewares "middlewares"} = middlewares;
                kind = "Rule";
                match = "Host${if regex then "Regexp" else ""}(`${domain}`)";
                services = [
                  ({
                    inherit namespace port;
                    name = service;
                    passHostHeader = true;
                    scheme = serviceScheme;
                  } // extraService)
                ] ++ extraServices;
              } // extraRule)
            ] ++ extraRoutes;
          } // tlsOptions // extraSpec;
        };
    };
  };
in
traefik
