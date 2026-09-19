# [Envoy Gateway](https://github.com/envoyproxy/gateway) manages Envoy using Kubernetes Gateway API.
{ hex, pkgs, ... }:
let
  inherit (pkgs.lib) optionalAttrs;
  apiVersion = "gateway.envoyproxy.io/v1alpha1";
  resource = kind: setup: {
    setup = args: { inherit kind apiVersion; } // setup args;
    build = args: hex.toYAMLDoc ((resource kind setup).setup args);
  };
  metadata = { name, namespace, labels, annotations }: {
    inherit name namespace;
    annotations = hex.annotations // annotations;
  } // optionalAttrs (labels != { }) { inherit labels; };
  policy = kind: resource kind
    ({ name, targetRefs, spec, namespace ? "default", labels ? { }, annotations ? { } }:
      assert pkgs.lib.assertMsg (targetRefs != [ ]) "envoy-gateway: a policy needs at least one targetRef";
      {
        metadata = metadata { inherit name namespace labels annotations; };
        spec = spec // { inherit targetRefs; };
      });
in
rec {
  docs_meta = {
    source = "https://github.com/envoyproxy/gateway";
    notes = [ "See the [Envoy Gateway guide](/integration-envoy-gateway) for Gateway API helpers, policy builders and Traefik migration examples." ];
  };
  defaults = { name = "envoy-gateway"; namespace = "envoy-gateway-system"; };
  chart_url = version: "oci://docker.io/envoyproxy/gateway-helm:v${version}";
  values_url = "https://github.com/envoyproxy/gateway/blob/v1.9.1/charts/gateway-helm/values.yaml";
  version = hex.k8s._.versionMap { inherit chart; versionFile = ./envoy-gateway.json; };
  # Preserve cluster-scoped resource metadata; never force a namespace onto CRDs or RBAC.
  chart =
    { name ? defaults.name
    , namespace ? defaults.namespace
    , version
    , sha256
    , valuesAttrs ? { }
    , sets ? [ ]
    , extraFlags ? [ ]
    , includeCRDs ? true
    , kubeVersion ? "1.35"
    , sortYaml ? false
    }: hex.k8s.helm.build {
      inherit name namespace version sha256 valuesAttrs sets extraFlags includeCRDs kubeVersion sortYaml;
      url = chart_url version;
      forceNamespace = false;
      # The pinned formatter corrupts explicitly indented CRD block descriptions.
      # Quote them before formatting, preserving their exact string values.
      postRender = ''
        ${hex._.yq} -i '(select(.kind == "CustomResourceDefinition") | .. | select(tag == "!!map" and has("description")) | .description | select(tag == "!!str")) style = "double"' "$out"
      '';
    };

  # docs: reference a same-namespace policy target, optionally selecting a listener or route rule.
  target_ref = { name, kind ? "HTTPRoute", sectionName ? null }: {
    inherit name kind;
    group = "gateway.networking.k8s.io";
  } // optionalAttrs (sectionName != null) { inherit sectionName; };

  security_policy = policy "SecurityPolicy";
  backend_traffic_policy = policy "BackendTrafficPolicy";
  client_traffic_policy = policy "ClientTrafficPolicy";
  extension_policy = policy "EnvoyExtensionPolicy";

  # Policy fragments compose into ONE policy per target and policy kind.
  security = {
    ip_allowlist = ips: {
      authorization = {
        defaultAction = "Deny";
        rules = if ips == [ ] then [ ] else [{ action = "Allow"; principal.clientCIDRs = ips; }];
      };
    };
    cors = spec: { cors = spec; };
    jwt = providers: { jwt = { inherit providers; }; };
    oidc = spec: { oidc = spec; };
    basic_auth = secretName: { basicAuth.users.name = secretName; };
    ext_auth = spec: { extAuth = spec; };
  };

  traffic = {
    compress = types: {
      compressor = map
        (type:
          assert pkgs.lib.assertMsg (builtins.elem type [ "Gzip" "Brotli" "Zstd" ]) "envoy-gateway: unsupported compressor";
          { inherit type; ${pkgs.lib.toLower type} = { }; })
        types;
    };
    local_rate_limit = { requests, unit ? "Second" }: {
      rateLimit.local.rules = [{ limit = { inherit requests unit; }; }];
    };
    retry = spec: { retry = spec; };
    timeout = spec: { timeout = spec; };
    circuit_breaker = spec: { circuitBreaker = spec; };
    load_balancer = spec: { loadBalancer = spec; };
    health_check = spec: { healthCheck = spec; };
  };

  client = {
    # Only trust a hop count after checking the actual ingress proxy topology.
    trusted_hops = hops: { clientIPDetection.xForwardedFor.numTrustedHops = hops; };
    tls = spec: { tls = spec; };
    http1 = spec: { http1 = spec; };
  };

  # docs: configure the managed Envoy data plane; reference this from Gateway.infrastructure.parametersRef.
  envoy_proxy = resource "EnvoyProxy"
    ({ name
     , namespace ? "default"
     , replicas ? 2
     , serviceType ? "LoadBalancer"
     , serviceAnnotations ? { }
     , externalTrafficPolicy ? null
     , extraSpec ? { }
     , labels ? { }
     , annotations ? { }
     }: {
      metadata = metadata { inherit name namespace labels annotations; };
      spec = pkgs.lib.recursiveUpdate
        {
          provider = {
            type = "Kubernetes";
            kubernetes = {
              envoyDeployment = { inherit replicas; };
              envoyService = {
                type = serviceType;
                annotations = serviceAnnotations;
              } // optionalAttrs (externalTrafficPolicy != null) { inherit externalTrafficPolicy; };
            };
          };
        }
        extraSpec;
    });

  # docs: reference an EnvoyProxy in the same namespace as the Gateway.
  proxy_ref = name: { group = "gateway.envoyproxy.io"; kind = "EnvoyProxy"; inherit name; };

  filters = {
    regex_rewrite = { pattern, substitution }: {
      urlRewrite.path = { type = "ReplaceRegexMatch"; replaceRegexMatch = { inherit pattern substitution; }; };
    };
    add_prefix = prefix: filters.regex_rewrite { pattern = "^/"; substitution = "${prefix}/"; };
    default_index = filters.regex_rewrite { pattern = "^/$"; substitution = "/index.html"; };
    direct_response = { statusCode, body ? "", contentType ? "text/plain" }: {
      directResponse = { inherit statusCode contentType; body = { type = "Inline"; inline = body; }; };
    };
    ref = name: hex.k8s.gateway-api.filters.extension { inherit name; group = "gateway.envoyproxy.io"; kind = "HTTPRouteFilter"; };
  };

  # docs: build an Envoy HTTPRouteFilter for regex rewrites or direct responses, then attach via ExtensionRef.
  http_route_filter = resource "HTTPRouteFilter"
    ({ name, spec, namespace ? "default", labels ? { }, annotations ? { } }: {
      inherit spec;
      metadata = metadata { inherit name namespace labels annotations; };
    });
}
