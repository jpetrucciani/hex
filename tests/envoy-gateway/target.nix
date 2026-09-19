{ hex }:
let
  g = hex.k8s.gateway-api;
  e = hex.k8s.envoy-gateway;
  parents = [ (g.parent_ref { name = "edge"; namespace = "infra"; sectionName = "https"; }) ];
  targets = [ (e.target_ref { name = "app"; }) ];
  backend = g.backend_ref { name = "app"; port = 8080; };
in
hex [
  (g.gateway_class.build { name = "envoy"; controllerName = "gateway.envoyproxy.io/gatewayclass-controller"; })
  (g.gateway.build {
    name = "edge";
    namespace = "infra";
    gatewayClassName = "envoy";
    listeners = [
      (g.listeners.http { allowedRoutes.namespaces.from = "All"; })
      (g.listeners.https { secretName = "example-tls"; allowedRoutes.namespaces.from = "All"; })
      (g.listeners.tcp { name = "postgres"; port = 5432; })
      (g.listeners.udp { name = "dns"; port = 53; })
      (g.listeners.tls { name = "passthrough"; port = 8443; })
    ];
    extraSpec.infrastructure.parametersRef = e.proxy_ref "edge";
  })
  (e.envoy_proxy.build { name = "edge"; namespace = "infra"; externalTrafficPolicy = "Local"; })
  (g.http.build {
    name = "app";
    domain = "app.example.com";
    gateway = "edge";
    gatewayNamespace = "infra";
    sectionName = "https";
    port = 8080;
    matches = [ (g.matches.path_prefix "/api") ];
    filters = [
      g.filters.strip_prefix
      (g.filters.request_headers { set.X-Forwarded-Proto = "https"; remove = [ "X-Untrusted" ]; })
      (g.filters.response_headers { set.X-Frame-Options = "DENY"; add.X-Example = "test"; })
    ];
    timeouts = { request = "30s"; backendRequest = "15s"; };
    extraBackends = [ (g.backend_ref { name = "canary"; port = 8080; weight = 0; }) ];
  })
  (g.http.build { name = "loki"; domain = "logs.example.com"; gateway = "edge"; gatewayNamespace = "infra"; sectionName = "https"; service = "loki-gateway"; backendNamespace = "loki"; })
  (g.reference_grant.build { name = "loki-from-apps"; namespace = "loki"; fromNamespace = "default"; toName = "loki-gateway"; })
  (g.http_route.build {
    name = "redirect";
    parentRefs = [ (g.parent_ref { name = "edge"; namespace = "infra"; sectionName = "http"; }) ];
    rules = [{ filters = [ (g.filters.redirect { }) ]; }];
  })
  (g.grpc_route.build { name = "grpc"; parentRefs = parents; rules = [{ backendRefs = [ backend ]; }]; })
  (g.tcp_route.build { name = "postgres"; namespace = "infra"; parentRefs = [ (g.parent_ref { name = "edge"; sectionName = "postgres"; }) ]; rules = [{ backendRefs = [ (g.backend_ref { name = "postgres"; port = 5432; }) ]; }]; })
  (g.udp_route.build { name = "dns"; namespace = "infra"; parentRefs = [ (g.parent_ref { name = "edge"; sectionName = "dns"; }) ]; rules = [{ backendRefs = [ (g.backend_ref { name = "dns"; port = 53; }) ]; }]; })
  (g.tls_route.build { name = "tls"; namespace = "infra"; hostnames = [ "tls.example.com" ]; parentRefs = [ (g.parent_ref { name = "edge"; sectionName = "passthrough"; }) ]; rules = [{ backendRefs = [ (g.backend_ref { name = "tls"; port = 443; }) ]; }]; })
  (g.backend_tls_policy.build { name = "upstream-tls"; service = "secure"; hostname = "secure.example.com"; })
  (g.backend_tls_policy.build { name = "private-ca"; service = "private"; hostname = "private.example.com"; caCertificateRefs = [{ group = ""; kind = "ConfigMap"; name = "private-ca"; }]; })
  (e.security_policy.build { name = "app"; targetRefs = targets; spec = e.security.ip_allowlist [ "10.0.0.0/8" "100.64.0.0/10" ]; })
  (e.security_policy.build { name = "deny-all"; targetRefs = [ (e.target_ref { name = "locked"; }) ]; spec = e.security.ip_allowlist [ ]; })
  (e.security_policy.build {
    name = "auth";
    targetRefs = [ (e.target_ref { name = "authenticated"; }) ];
    spec = e.security.basic_auth "users" // e.security.cors { allowOrigins = [ "https://example.com" ]; allowMethods = [ "GET" ]; };
  })
  (e.backend_traffic_policy.build {
    name = "app";
    targetRefs = targets;
    spec = e.traffic.compress [ "Gzip" "Brotli" "Zstd" ] // e.traffic.local_rate_limit { requests = 100; };
  })
  (e.client_traffic_policy.build { name = "edge"; namespace = "infra"; targetRefs = [ (e.target_ref { name = "edge"; kind = "Gateway"; }) ]; spec = e.client.trusted_hops 1 // e.client.tls { minVersion = "1.2"; }; })
  (e.http_route_filter.build { name = "add-prefix"; spec = e.filters.add_prefix "/app"; })
  (e.http_route_filter.build { name = "default-index"; spec = e.filters.default_index; })
  (e.http_route_filter.build { name = "regex"; spec = e.filters.regex_rewrite { pattern = "^/old/(.*)$"; substitution = "/new/\\1"; }; })
  (e.http_route_filter.build { name = "maintenance"; spec = e.filters.direct_response { statusCode = 503; body = "Try later\n"; }; })
  (g.http_route.build {
    name = "index";
    parentRefs = parents;
    rules = [{ matches = [ (g.matches.path_exact "/") ]; filters = [ (e.filters.ref "default-index") ]; backendRefs = [ backend ]; }];
  })
  (g.http_route.build {
    name = "mirror";
    parentRefs = parents;
    rules = [{ filters = [ (g.filters.mirror (g.backend_ref { name = "shadow"; port = 8080; })) ]; backendRefs = [ backend ]; }];
  })
]
