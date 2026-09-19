# Envoy Gateway

Envoy Gateway configures Envoy through Kubernetes Gateway API. Hex exposes portable
resources as `hex.k8s.gateway-api` and Envoy-specific installation and policies as
`hex.k8s.envoy-gateway`.

The bundled chart is pinned to **Envoy Gateway 1.9.1**. Helpers target its bundled
CRDs: Gateway API `v1` (including BackendTLSPolicy and TCP/UDP/TLS routes),
ReferenceGrant `v1beta1`, and Envoy extensions `v1alpha1`. Older controller/CRD
versions may not support these fields.

For a complete runnable demo with two echo backends, see
[examples/envoy-gateway.nix](https://github.com/jpetrucciani/hex/blob/main/examples/envoy-gateway.nix)
and its [run instructions](https://github.com/jpetrucciani/hex/blob/main/examples/README.md).

## Install and expose an application

```nix
{ hex, ... }:
let
  g = hex.k8s.gateway-api;
  e = hex.k8s.envoy-gateway;
in
hex [
  (e.version.latest { })
  (g.gateway_class.build {
    name = "envoy";
    controllerName = "gateway.envoyproxy.io/gatewayclass-controller";
  })
  (g.gateway.build {
    name = "edge";
    namespace = "default";
    gatewayClassName = "envoy";
    listeners = [
      (g.listeners.http { })
      (g.listeners.https { secretName = "example-com-tls"; })
    ];
    extraSpec.infrastructure.parametersRef = e.proxy_ref "edge";
  })
  (e.envoy_proxy.build {
    name = "edge";
    replicas = 2;
    serviceType = "LoadBalancer";
    # Cloud-specific internal/public LB annotations belong here.
    serviceAnnotations = { };
  })
  (g.http.build {
    name = "app";
    domain = "app.example.com";
    gateway = "edge";
    sectionName = "https";
    service = "app-service";
    port = 8080;
  })
  (g.http_route.build {
    name = "https-redirect";
    parentRefs = [ (g.parent_ref { name = "edge"; sectionName = "http"; }) ];
    rules = [{ filters = [ (g.filters.redirect { }) ]; }];
  })
]
```

Create the TLS Secret `example-com-tls` in the Gateway's namespace through your
existing secret/certificate tooling. TLS termination belongs to the listener,
not each route. Select `sectionName` so the HTTPS route does not also attach to
the HTTP listener. There is no automatic redirect or certificate issuance.

The Helm chart installs the controller and CRDs; the controller creates the
actual Envoy Deployment and Service from Gateway/EnvoyProxy resources. Controller
replicas are configured with `valuesAttrs.deployment.replicas`; proxy replicas
are configured with `envoy_proxy`. They are separate workloads.

Render/install the controller and CRDs first, wait for CRDs to become established
and the controller to become ready, then apply Gateways, routes and policies.
All-in-one YAML is convenient for rendering but does not enforce that ordering.
For GitOps, express it using the tool's dependency or sync ordering mechanism.
Check the upstream [compatibility matrix](https://gateway.envoyproxy.io/docs/compatibility-matrix/)
for the target Kubernetes release.

If compatible CRDs are managed separately, use:

```nix
e.version.latest {
  includeCRDs = false;
  valuesAttrs.crds.enabled = false;
}
```

This disables both Helm CRD inclusion and the chart's CRD subchart. Coordinate
cluster-wide Gateway API CRD ownership with other installed controllers. See
[upstream installation guidance](https://gateway.envoyproxy.io/docs/install/install-helm/).

## Routing and filters

Resource helpers expose `.setup args` for a Nix attrset and `.build args` for a
YAML document. Listener, match, reference, filter and policy-fragment helpers
return attrsets to compose into those resources.

| Helper | Purpose |
| --- | --- |
| `g.http` | Single hostname, service and Gateway shorthand |
| `g.http_route`, `g.grpc_route` | Explicit `parentRefs`, `rules`, optional `hostnames` |
| `g.tcp_route`, `g.udp_route`, `g.tls_route` | L4 routing and SNI-based TLS passthrough |
| `g.listeners.http/https/tcp/udp/tls` | Listener objects; `tls` uses passthrough |
| `g.matches.path_prefix/path_exact/path_regex` | HTTP path matches; add `method`, `headers`, `queryParams` directly |
| `g.backend_ref` | Named Service, numeric port, optional namespace and weight |
| `g.filters.request_headers/response_headers` | `set`/`add` attrsets and a `remove` list |
| `g.filters.rewrite` | Host rewrite, `replaceFullPath` or `replacePrefixMatch` |
| `g.filters.strip_prefix` | Replace a matched path prefix with `/` |
| `g.filters.redirect` | HTTPS redirect by default; optional host, port and path |
| `g.filters.mirror` | Mirror to a backend reference |
| `g.filters.extension` | Reference an implementation-specific filter |
| `g.backend_tls_policy` | Verified TLS from Envoy to a backend Service |

For example, strip `/api` and set a response header:

```nix
g.http.build {
  name = "api";
  domain = "api.example.com";
  gateway = "edge";
  sectionName = "https";
  port = 8080;
  matches = [ (g.matches.path_prefix "/api") ];
  filters = [
    g.filters.strip_prefix
    (g.filters.response_headers { set.X-Frame-Options = "DENY"; })
  ];
  timeouts = { request = "30s"; backendRequest = "15s"; };
}
```

Prefix rewrites require a `PathPrefix` match. A redirect rule must not have
backends; use `http_route` for that case. Do not combine URLRewrite and
RequestRedirect in a rule. Gateway API filters are not an arbitrary ordered
Traefik middleware chain.

Use `http_route.rules[].backendRefs` and weighted `backend_ref` objects for
traffic splitting. `http.extraBackends` adds backends to the primary backend,
whose omitted weight defaults to 1. `http.extraRules` appends complete rules.
`extraSpec` merges additional top-level spec fields into resource helpers.

`port = 443` does **not** implicitly enable upstream TLS. Attach a
`backend_tls_policy` to the backend Service, specifying its certificate hostname
and either a trusted CA ConfigMap reference or the default system CA roots.
Frontend TLS and backend TLS are independent. The helper does not disable
certificate verification.

## Cross-namespace routing

Prefer placing routes alongside their Services. Routes attaching to a Gateway
in another namespace need `gatewayNamespace` (or `parent_ref.namespace`), plus
that listener's `allowedRoutes.namespaces` permitting their namespace. Listeners
default to `Same`; use a namespace label selector when sharing a Gateway.

For an existing wrapper which keeps routes in `default` but sends traffic to
`loki/loki-gateway`, render both:

```nix
g.http.build {
  name = "loki";
  domain = "logs.example.com";
  namespace = "default";
  gateway = "edge";
  sectionName = "https";
  service = "loki-gateway";
  backendNamespace = "loki";
  port = 80;
}

g.reference_grant.build {
  name = "loki-from-default";
  namespace = "loki";
  fromNamespace = "default";
  toName = "loki-gateway";
}
```

A ReferenceGrant is created in the **destination** namespace and permits only
the named target. It authorizes routes of the specified kind from the source
namespace, not a single named source route. Route-to-Gateway attachment uses
`allowedRoutes`, not ReferenceGrant. See the
[Gateway API security model](https://gateway-api.sigs.k8s.io/concepts/security-model/).

## Envoy policies

Policies attach to resources in their own namespace. Compose fragments into
**one policy per kind and target**, rather than creating competing policies:

```nix
let
  targetRefs = [ (e.target_ref { name = "app"; }) ];
in
hex [
  (e.security_policy.build {
    name = "app-security";
    inherit targetRefs;
    spec = e.security.ip_allowlist [ "10.0.0.0/8" "100.64.0.0/10" ];
  })
  (e.backend_traffic_policy.build {
    name = "app-traffic";
    inherit targetRefs;
    spec = e.traffic.compress [ "Gzip" "Brotli" ]
      // e.traffic.local_rate_limit { requests = 100; unit = "Second"; };
  })
]
```

An empty IP allowlist denies all requests. Local rate limits are per Envoy
instance, not a shared global quota. Explicit route-level policies can override
Gateway-level behavior; do not assume an allowlist on a Gateway is an immutable
security boundary for other tenants' routes. Review
[policy attachment](https://gateway.envoyproxy.io/docs/concepts/gateway_api_extensions/security-policy/)
and route ownership before sharing a Gateway.

| Policy | Fragment helpers / configuration |
| --- | --- |
| `e.security_policy` | `security.ip_allowlist`, `cors`, `jwt`, `oidc`, `basic_auth`, `ext_auth` |
| `e.backend_traffic_policy` | `traffic.compress`, `local_rate_limit`, `retry`, `timeout`, `circuit_breaker`, `load_balancer`, `health_check` |
| `e.client_traffic_policy` | `client.trusted_hops`, `tls`, `http1`; targets a Gateway/listener |
| `e.extension_policy` | Native EnvoyExtensionPolicy `spec` for Lua, Wasm, external processing |

Other than the convenience helpers shown above, fragments take the upstream
field's native object shape. `security.jwt` takes a providers list;
`security.basic_auth` takes a Secret name containing the `.htpasswd` key.
OIDC, external auth and other secrets remain Kubernetes Secret references.
Pass additional upstream fields directly in `spec`; Hex does not attempt to
reimplement the entire [Envoy extension schema](https://gateway.envoyproxy.io/docs/api/extension_types/).

For traffic arriving through Caddy, a cloud LB or Tailscale, verify which client
IP reaches Envoy before moving an allowlist. `client.trusted_hops n` configures
`X-Forwarded-For` trust on a Gateway's ClientTrafficPolicy. Configure this only
for the actual trusted proxy chain, and prevent clients from bypassing that
chain. `envoy_proxy.externalTrafficPolicy = "Local"` can preserve source IPs for
appropriate Service/LB setups; it is not a substitute for checking the topology.

## Traefik migration

| Existing Traefik behavior | Envoy/Gateway API equivalent |
| --- | --- |
| `ingress_route` / `Host(...)` | `g.http`; Gateway API hostnames support exact names and wildcard suffixes, not arbitrary HostRegexp expressions |
| `internal` / ingress class annotation | Explicit Gateway selection and EnvoyProxy Service configuration |
| Per-route `secretName` | HTTPS Gateway listener with `secretName` |
| `strip_prefix` | `PathPrefix` match plus `g.filters.strip_prefix` |
| Request/response headers | Standard header filters |
| `ip_allowlist` | SecurityPolicy authorization |
| `compress` | BackendTrafficPolicy compressor |
| `add_prefix`, `default_index`, regex replacement | Envoy HTTPRouteFilter referenced through ExtensionRef |

Envoy-specific path transforms use a named resource:

```nix
hex [
  (e.http_route_filter.build {
    name = "default-index";
    spec = e.filters.default_index;
  })
  (g.http.build {
    name = "site";
    domain = "site.example.com";
    gateway = "edge";
    sectionName = "https";
    filters = [ (e.filters.ref "default-index") ];
  })
]
```

Also available: `e.filters.add_prefix "/app"`,
`e.filters.regex_rewrite { pattern = "^/old/(.*)$"; substitution = "/new/\\1"; }`,
and `e.filters.direct_response { statusCode = 503; body = "Try later"; }`.
These return `HTTPRouteFilter.spec` fragments and use Envoy/RE2 regex semantics.

Your host-specific wrapper can stay small:

```nix
route = { name, domain, namespace ? "default", service ? name, port ? 10000 }:
  g.http.build {
    inherit name domain namespace service port;
    gateway = "edge";
    gatewayNamespace = "infra";
    sectionName = "https";
  };
```

This wrapper puts each route alongside its backend, unlike the Traefik wrapper's
separate backend namespace. Configure the `infra/edge` listener to admit these
namespaces. Attach IP policies in the route's namespace, or deliberately on a
Gateway. Public/internal selection can choose different Gateways with different
EnvoyProxy Service settings. Existing ops deployments are not migrated by adding
these Hex helpers.

## Validation

Run the focused tests with `./result/bin/test envoy-gateway-resources,envoy-gateway-chart,gateway-api-invalid-rewrite,envoy-gateway-empty-targets,envoy-gateway-invalid-compressor`
after building `.#test`. Resource tests validate against the CRD schemas from the
pinned chart, with no missing-schema skips in that check. JSON Schema checks do
not execute Kubernetes CEL validations or prove controller acceptance. Before a
migration, test in a cluster and inspect `Accepted`, `ResolvedRefs`, and
`Programmed` status conditions, plus actual HTTP/TLS and client-IP behavior.
