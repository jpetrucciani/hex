# Portable Kubernetes Gateway API resources and composable HTTP rule fragments.
{ hex, pkgs }:
let
  inherit (pkgs.lib) optionalAttrs;
  group = "gateway.networking.k8s.io";
  resource = kind: apiVersion: setup: {
    setup = args:
      let
        result = setup args;
      in
      { inherit kind apiVersion; } // result;
    build = args: hex.toYAMLDoc ((resource kind apiVersion setup).setup args);
  };
  metadata = { name, namespace ? "default", labels ? { }, annotations ? { } }: {
    inherit name namespace;
    annotations = hex.annotations // annotations;
  } // optionalAttrs (labels != { }) { inherit labels; };
  route = kind: apiVersion: resource kind apiVersion
    ({ name, namespace ? "default", parentRefs, rules, hostnames ? [ ], labels ? { }, annotations ? { }, extraSpec ? { } }: {
      metadata = metadata { inherit name namespace labels annotations; };
      spec = { inherit parentRefs rules; }
        // optionalAttrs (hostnames != [ ]) { inherit hostnames; }
        // extraSpec;
    });
  headerFilter = type: field: { set ? { }, add ? { }, remove ? [ ] }:
    let
      entries = pkgs.lib.mapAttrsToList (name: value: { inherit name value; });
    in
    {
      inherit type;
      ${field} = optionalAttrs (set != { }) { set = entries set; }
        // optionalAttrs (add != { }) { add = entries add; }
        // optionalAttrs (remove != [ ]) { inherit remove; };
    };
in
rec {
  # docs: build or render a cluster-scoped GatewayClass for a controller.
  gateway_class = resource "GatewayClass" "${group}/v1"
    ({ name, controllerName, parametersRef ? null, labels ? { }, annotations ? { }, extraSpec ? { } }: {
      metadata = builtins.removeAttrs (metadata { inherit name labels annotations; }) [ "namespace" ];
      spec = { inherit controllerName; }
        // optionalAttrs (parametersRef != null) { inherit parametersRef; }
        // extraSpec;
    });

  # docs: build or render a Gateway with explicit listeners and route attachment rules.
  gateway = resource "Gateway" "${group}/v1"
    ({ name, gatewayClassName, listeners, namespace ? "default", labels ? { }, annotations ? { }, extraSpec ? { } }: {
      metadata = metadata { inherit name namespace labels annotations; };
      spec = { inherit gatewayClassName listeners; } // extraSpec;
    });

  listeners = {
    http = { name ? "http", port ? 80, hostname ? null, allowedRoutes ? { namespaces.from = "Same"; } }: {
      inherit name port allowedRoutes;
      protocol = "HTTP";
    } // optionalAttrs (hostname != null) { inherit hostname; };
    https = { secretName, name ? "https", port ? 443, hostname ? null, allowedRoutes ? { namespaces.from = "Same"; } }: {
      inherit name port allowedRoutes;
      protocol = "HTTPS";
      tls = { mode = "Terminate"; certificateRefs = [{ name = secretName; kind = "Secret"; group = ""; }]; };
    } // optionalAttrs (hostname != null) { inherit hostname; };
    tls = { name ? "tls", port ? 443, hostname ? null, allowedRoutes ? { namespaces.from = "Same"; } }: {
      inherit name port allowedRoutes;
      protocol = "TLS";
      tls.mode = "Passthrough";
    } // optionalAttrs (hostname != null) { inherit hostname; };
    tcp = { name, port, allowedRoutes ? { namespaces.from = "Same"; } }: { inherit name port allowedRoutes; protocol = "TCP"; };
    udp = { name, port, allowedRoutes ? { namespaces.from = "Same"; } }: { inherit name port allowedRoutes; protocol = "UDP"; };
  };

  # docs: reference a Gateway, optionally in another namespace or on a specific listener.
  parent_ref = { name, namespace ? null, sectionName ? null }: { inherit name; }
    // optionalAttrs (namespace != null) { inherit namespace; }
    // optionalAttrs (sectionName != null) { inherit sectionName; };

  # docs: reference a Service backend, optionally weighted or cross-namespace.
  backend_ref = { name, port, namespace ? null, weight ? null }: {
    inherit name port;
    group = "";
    kind = "Service";
  } // optionalAttrs (namespace != null) { inherit namespace; }
  // optionalAttrs (weight != null) { inherit weight; };

  http_route = route "HTTPRoute" "${group}/v1";
  grpc_route = route "GRPCRoute" "${group}/v1";
  # API versions match the CRDs bundled with Envoy Gateway 1.9.1.
  tcp_route = route "TCPRoute" "${group}/v1";
  udp_route = route "UDPRoute" "${group}/v1";
  tls_route = route "TLSRoute" "${group}/v1";

  # docs: a single-host HTTPRoute, similar to Traefik's ingress_route helper.
  http = resource "HTTPRoute" "${group}/v1"
    ({ name
     , domain
     , gateway
     , namespace ? "default"
     , gatewayNamespace ? null
     , sectionName ? null
     , service ? name
     , port ? 80
     , backendNamespace ? null
     , matches ? [ ]
     , filters ? [ ]
     , extraBackends ? [ ]
     , extraRules ? [ ]
     , timeouts ? { }
     , labels ? { }
     , annotations ? { }
     , extraSpec ? { }
     }: builtins.removeAttrs
      (http_route.setup {
        inherit name namespace labels annotations extraSpec;
        hostnames = [ domain ];
        parentRefs = [ (parent_ref { name = gateway; namespace = gatewayNamespace; inherit sectionName; }) ];
        rules = [
          ({
            backendRefs = [ (backend_ref { name = service; inherit port; namespace = backendNamespace; }) ] ++ extraBackends;
          } // optionalAttrs (matches != [ ]) { inherit matches; }
          // optionalAttrs (filters != [ ]) { inherit filters; }
          // optionalAttrs (timeouts != { }) { inherit timeouts; })
        ] ++ extraRules;
      }) [ "kind" "apiVersion" ]);

  matches = {
    # Additional fields support method, headers and queryParams without a DSL.
    path_prefix = value: { path = { type = "PathPrefix"; inherit value; }; };
    path_exact = value: { path = { type = "Exact"; inherit value; }; };
    path_regex = value: { path = { type = "RegularExpression"; inherit value; }; };
  };

  filters = {
    request_headers = headerFilter "RequestHeaderModifier" "requestHeaderModifier";
    response_headers = headerFilter "ResponseHeaderModifier" "responseHeaderModifier";
    # docs: rewrite the hostname or path, with explicit full-path or matched-prefix semantics.
    rewrite = { hostname ? null, replaceFullPath ? null, replacePrefixMatch ? null }:
      assert pkgs.lib.assertMsg (!(replaceFullPath != null && replacePrefixMatch != null)) "gateway-api: choose one path rewrite type";
      {
        type = "URLRewrite";
        urlRewrite = optionalAttrs (hostname != null) { inherit hostname; }
          // optionalAttrs (replaceFullPath != null) { path = { type = "ReplaceFullPath"; inherit replaceFullPath; }; }
          // optionalAttrs (replacePrefixMatch != null) { path = { type = "ReplacePrefixMatch"; inherit replacePrefixMatch; }; };
      };
    strip_prefix = filters.rewrite { replacePrefixMatch = "/"; };
    redirect = { scheme ? "https", statusCode ? 301, hostname ? null, port ? null, path ? null }: {
      type = "RequestRedirect";
      requestRedirect = { inherit scheme statusCode; }
        // optionalAttrs (hostname != null) { inherit hostname; }
        // optionalAttrs (port != null) { inherit port; }
        // optionalAttrs (path != null) { inherit path; };
    };
    mirror = backendRef: { type = "RequestMirror"; requestMirror = { inherit backendRef; }; };
    extension = { name, kind, group }: { type = "ExtensionRef"; extensionRef = { inherit name kind group; }; };
  };

  # docs: grant a source namespace access to a named backend Service in the grant namespace.
  reference_grant = resource "ReferenceGrant" "${group}/v1beta1"
    ({ name, namespace, fromNamespace, toName, fromKind ? "HTTPRoute", toKind ? "Service", toGroup ? "", labels ? { }, annotations ? { } }: {
      metadata = metadata { inherit name namespace labels annotations; };
      spec = {
        from = [{ inherit group; kind = fromKind; namespace = fromNamespace; }];
        to = [{ group = toGroup; kind = toKind; name = toName; }];
      };
    });

  # docs: configure verified TLS to a Service backend, independently of frontend TLS.
  backend_tls_policy = resource "BackendTLSPolicy" "${group}/v1"
    ({ name, service, hostname, namespace ? "default", caCertificateRefs ? [ ], sectionName ? null, labels ? { }, annotations ? { } }: {
      metadata = metadata { inherit name namespace labels annotations; };
      spec = {
        targetRefs = [
          ({ group = ""; kind = "Service"; name = service; }
            // optionalAttrs (sectionName != null) { inherit sectionName; })
        ];
        validation = { inherit hostname; }
          // (if caCertificateRefs == [ ] then { wellKnownCACertificates = "System"; } else { inherit caCertificateRefs; });
      };
    });
}
