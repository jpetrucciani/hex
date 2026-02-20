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
      # docs: render a Middleware resource to YAML using the args accepted by middleware.setup.
      build = args: toYAMLDoc (setup args);
      # docs: build a generic Middleware resource attrset for custom middleware specs.
      setup =
        { name  # type: string; Middleware resource name
        , spec  # type: attrset; middleware spec body (addPrefix/stripPrefix/etc)
        , kind ? "Middleware"  # type: string; Kubernetes resource kind to render
        , pre23 ? false  # type: bool; use legacy traefik.containo.us API group
        , apiVersion ? if pre23 then "traefik.containo.us/v1alpha1" else "traefik.io/v1alpha1"  # type: string; override Traefik CRD apiVersion
        , extraSpec ? { }  # type: attrset; extra fields merged at resource root
        }: {
          inherit kind apiVersion spec;
          metadata = {
            inherit name;
          };
        } // extraSpec;
      _ = {
        # docs: create an addPrefix middleware that prepends a path prefix.
        add_prefix =
          { prefix  # type: string; prefix to prepend to request paths
          , name ? "add-prefix"  # type: string; Middleware resource name
          , extraSpec ? { }  # type: attrset; extra fields merged at resource root
          }: build {
            inherit name extraSpec;
            spec = {
              addPrefix = {
                inherit prefix;
              };
            };
          };
        # docs: create a compress middleware for HTTP response compression.
        compress =
          { name ? "compress"  # type: string; Middleware resource name
          , extraSpec ? { }  # type: attrset; extra fields merged at resource root
          }: build {
            inherit name extraSpec;
            spec = {
              compress = { };
            };
          };
        # docs: create a middleware that rewrites / to /index.html.
        default_index =
          { name ? "default-index"  # type: string; Middleware resource name
          , extraSpec ? { }  # type: attrset; extra fields merged at resource root
          }: build {
            inherit name extraSpec;
            spec = {
              replacePathRegex = {
                regex = "^/$";
                replacement = "/index.html";
              };
            };
          };
        # docs: create an ipAllowList middleware with allowed source ranges.
        ip_allowlist =
          { ips  # type: list; CIDR ranges allowed to access matching routes
          , name ? "ip-allowlist"  # type: string; Middleware resource name
          , extraSpec ? { }  # type: attrset; extra fields merged at resource root
          }: build {
            inherit name extraSpec;
            spec = {
              ipAllowList.sourceRange = ips;
            };
          };
        # docs: create a legacy ipWhiteList middleware with allowed source ranges.
        ip_whitelist =
          { ips  # type: list; CIDR ranges allowed to access matching routes
          , name ? "ip-whitelist"  # type: string; Middleware resource name
          , extraSpec ? { }  # type: attrset; extra fields merged at resource root
          }: build {
            inherit name extraSpec;
            spec = {
              ipWhiteList.sourceRange = ips;
            };
          };
        # docs: create a stripPrefix middleware that removes path prefixes.
        strip_prefix =
          { prefixes  # type: list; prefixes to strip from request paths
          , name ? "strip-prefix"  # type: string; Middleware resource name
          , extraSpec ? { }  # type: attrset; extra fields merged at resource root
          }: build {
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
      # docs: render an IngressRoute resource to YAML using the args accepted by ingress_route.setup.
      build = args: toYAMLDoc (setup args);
      # docs: build an IngressRoute resource attrset for host routing and middleware wiring.
      setup =
        { name  # type: string; IngressRoute resource name
        , domain  # type: string; host or host regexp matched by the route
        , regex ? false  # type: bool; use HostRegexp instead of Host
        , port ? 80  # type: number; backend service port
        , namespace ? "default"  # type: string; backend service namespace
        , service ? name  # type: string; backend service name
        , serviceScheme ? if port == 443 then "https" else "http"  # type: string; backend service scheme
        , extraService ? { }  # type: attrset; extra fields merged into primary service entry
        , extraServices ? [ ]  # type: list; additional service entries appended to services
        , internal ? true  # type: bool; switch ingress class between internal and external traefik
        , secretName ? ""  # type: string; TLS secret name, empty string disables TLS
        , labels ? [ ]  # type: list; metadata labels list inserted when non-empty
        , middlewares ? [ ]  # type: list; middleware refs attached to the route
        , extraRule ? { }  # type: attrset; extra fields merged into route rule
        , extraRoutes ? [ ]  # type: list; additional route entries appended to spec.routes
        , extraSpec ? { }  # type: attrset; extra fields merged into spec
        , ingressRouteNamespace ? "default"  # type: string; namespace for the IngressRoute resource
        , pre23 ? false  # type: bool; use legacy traefik.containo.us API group
        , apiVersion ? if pre23 then "traefik.containo.us/v1alpha1" else "traefik.io/v1alpha1"  # type: string; override Traefik CRD apiVersion
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
