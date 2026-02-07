# [Traefik](https://github.com/traefik/traefik-helm-chart) is a modern HTTP reverse proxy and load balancer made to deploy microservices with ease.
{ hex, pkgs, ... }:
let
  inherit (hex) toYAML toYAMLDoc ifNotEmptyList;

  traefik = rec {
    defaults = {
      name = "traefik";
      namespace = "traefik";
    };
    index_url = "https://traefik.github.io/charts/index.yaml";
    chart_url = version: "https://traefik.github.io/charts/traefik/traefik-${version}.tgz";
    values_url = "https://github.com/traefik/traefik-helm-chart/blob/master/traefik/values.yaml";
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./traefik.json; };
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
