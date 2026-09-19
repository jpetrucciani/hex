# Run from the repo root: nix run path:.#hex -- --render -t examples/envoy-gateway.nix
# See examples/README.md for installation order and curl commands.
{ hex, ... }:
let
  g = hex.k8s.gateway-api;
  e = hex.k8s.envoy-gateway;
  namespace = "envoy-example";

  # An echo server makes rewritten paths and injected headers visible in curl.
  backend = name: hex.k8s.services.build {
    inherit name namespace;
    labels.app = name;
    image = "traefik/whoami:v1.12.0";
    port = 8080;
    envAttrs.WHOAMI_PORT_NUMBER = "8080";
    replicas = 1;
    cpuRequest = "10m";
    memoryRequest = "32Mi";
    autoscale = false;
    networkPolicy = false;
    roleBinding = false;
  };

  # Shared defaults stay in a small wrapper, just like a Traefik route wrapper.
  route = { name, path ? "/", filters ? [ ] }: g.http.build {
    inherit name namespace;
    domain = "app.example.test";
    matches = [ (g.matches.path_prefix path) ];
    gateway = "edge";
    sectionName = "http";
    service = "${name}-service";
    port = 8080;
    filters = filters ++ [
      (g.filters.request_headers { set.X-Example-Gateway = "hex"; })
      (g.filters.response_headers { set.X-Example-Route = name; })
    ];
  };
in
hex [
  # The controller chart includes both Gateway API and Envoy policy CRDs.
  (e.version.v1-9-1 { })
  (hex.toYAMLDoc {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = namespace;
  })
  (g.gateway_class.build {
    name = "envoy-example";
    controllerName = "gateway.envoyproxy.io/gatewayclass-controller";
  })
  (e.envoy_proxy.build {
    name = "edge";
    inherit namespace;
    replicas = 1;
    serviceType = "ClusterIP";
  })
  (g.gateway.build {
    name = "edge";
    inherit namespace;
    gatewayClassName = "envoy-example";
    listeners = [ (g.listeners.http { }) ];
    extraSpec.infrastructure.parametersRef = e.proxy_ref "edge";
  })

  (backend "web")
  (backend "api")

  # One hostname: /api and /api/* go to API, everything else goes to web.
  # Gateway API chooses the longest matching prefix, independent of list order.
  (route { name = "web"; })

  # Strip /api before forwarding: /api/hello -> api-service:8080/hello.
  (route {
    name = "api";
    path = "/api";
    filters = [ g.filters.strip_prefix ];
  })

  # Envoy's middleware-like features attach as policies to a route (or Gateway).
  # Compose fragments into one policy of each kind per target.
  (e.backend_traffic_policy.build {
    name = "api-traffic";
    inherit namespace;
    targetRefs = [ (e.target_ref { name = "api"; }) ];
    spec = e.traffic.compress [ "Gzip" ]
      // e.traffic.local_rate_limit { requests = 10; unit = "Second"; };
  })
]
