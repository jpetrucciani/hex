{ deps, pkgs, yq_assert }:
let
  e = deps.hex.k8s.envoy-gateway;
  pin = builtins.head (builtins.fromJSON (builtins.readFile ../hex/hex/k8s/helm/envoy-gateway/envoy-gateway.json));
  chart = deps.hex.fetchOCIChart { url = e.chart_url pin.version; inherit (pin) sha256; };
  yq = "${pkgs.yq-go}/bin/yq";
  schemaCheck = ''
    schemas="$(${pkgs.coreutils}/bin/mktemp -d)"
    for crd_file in ${chart}/charts/crds/crds/gatewayapi-crds.yaml ${chart}/charts/crds/crds/generated/*.yaml; do
      ${yq} -o=json -I=0 '. | select(.kind == "CustomResourceDefinition")' "$crd_file" |
      while IFS= read -r crd; do
        kind="$(printf '%s' "$crd" | ${yq} -p=json -r '.spec.names.kind | downcase')"
        for version in $(printf '%s' "$crd" | ${yq} -p=json -r '.spec.versions[] | select(.served) | .name'); do
          printf '%s' "$crd" | VERSION="$version" ${yq} -p=json -o=json '.spec.versions[] | select(.name == strenv(VERSION)) | .schema.openAPIV3Schema' > "$schemas/''${kind}_''${version}.json"
        done
      done
    done
    ${pkgs.kubeconform}/bin/kubeconform -strict -summary \
      -schema-location "$schemas/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json" "$rendered"
    schema_status=$?
    rm -rf "$schemas"
    [ "$schema_status" -eq 0 ] || exit "$schema_status"
  '';
in
[
  {
    name = "envoy-gateway-resources";
    suites = [ "fast" ];
    spec = ''import ${./envoy-gateway/target.nix} { inherit hex; }'';
    expectedDocuments = 24;
    check = ''
      ${schemaCheck}
      ${yq_assert ''select(.kind == "GatewayClass") | has("metadata") and (.metadata | has("namespace") | not)'' "GatewayClass must be cluster-scoped"}
      ${yq_assert ''select(.kind == "HTTPRoute" and .metadata.name == "loki") | .metadata.namespace == "default" and .spec.rules[0].backendRefs[0].namespace == "loki" and .spec.parentRefs[0].namespace == "infra"'' "route, backend and Gateway namespaces must remain independent"}
      ${yq_assert ''select(.kind == "ReferenceGrant") | .metadata.namespace == "loki" and .spec.to[0].name == "loki-gateway" and .spec.from[0].namespace == "default"'' "ReferenceGrant must grant only the named backend"}
      ${yq_assert ''select(.kind == "HTTPRoute" and .metadata.name == "redirect") | .spec.rules[0].filters[0].requestRedirect.scheme == "https" and (.spec.rules[0] | has("backendRefs") | not)'' "redirect rules must not forward to a backend"}
      ${yq_assert ''select(.kind == "SecurityPolicy" and .metadata.name == "deny-all") | .spec.authorization.defaultAction == "Deny" and (.spec.authorization.rules | tag) == "!!seq" and (.spec.authorization.rules | length) == 0'' "empty allowlist must deny all"}
      ${yq_assert ''select(.kind == "BackendTrafficPolicy") | (.spec.compressor[0].gzip | tag) == "!!map" and (.spec.compressor[0].gzip | length) == 0 and .spec.rateLimit.local.rules[0].limit.requests == 100'' "compression and rate limiting must compose into one policy"}
      ${yq_assert ''select(.kind == "HTTPRouteFilter" and .metadata.name == "regex") | .spec.urlRewrite.path.replaceRegexMatch.substitution == "/new/\1"'' "regex backreferences must survive YAML rendering"}
    '';
  }
  {
    name = "envoy-gateway-chart";
    suites = [ "charts" ];
    spec = "hex.k8s.envoy-gateway.version.latest {}";
    check = ''
      ${yq_assert ''select(.kind == "Deployment") | .metadata.namespace == "envoy-gateway-system" and .metadata.name == "envoy-gateway"'' "controller Deployment missing"}
      ${yq_assert ''select(.kind == "CustomResourceDefinition" and .metadata.name == "securitypolicies.gateway.envoyproxy.io") | .metadata | has("namespace") | not'' "Envoy CRDs must be present and cluster-scoped"}
      ${yq_assert ''select(.kind == "CustomResourceDefinition" and .metadata.name == "httproutes.gateway.networking.k8s.io") | .metadata | has("namespace") | not'' "Gateway API CRDs must be present and cluster-scoped"}
    '';
  }
  {
    name = "envoy-gateway-example";
    suites = [ "charts" ];
    spec = ''import ${../examples/envoy-gateway.nix} { inherit hex; }'';
    check = ''
      ${yq_assert ''select(.kind == "Deployment" and .metadata.name == "web") | .metadata.namespace == "envoy-example" and .spec.template.spec.containers[0].image == "traefik/whoami:v1.12.0"'' "example must include its demo backend"}
      ${yq_assert ''select(.kind == "ServiceAccount" and .metadata.name == "web-service-account") | .metadata.namespace == "envoy-example"'' "web backend's ServiceAccount must exist"}
      ${yq_assert ''select(.kind == "ServiceAccount" and .metadata.name == "api-service-account") | .metadata.namespace == "envoy-example"'' "API backend's ServiceAccount must exist"}
      ${yq_assert ''select(.kind == "Service" and .metadata.name == "api-service") | .spec.ports[0].port == 8080'' "API backend must expose the route's port"}
      ${yq_assert ''select(.kind == "HTTPRoute" and .metadata.name == "api") | .spec.hostnames[0] == "app.example.test" and .spec.parentRefs[0].name == "edge" and .spec.parentRefs[0].sectionName == "http" and .spec.rules[0].matches[0].path.type == "PathPrefix" and .spec.rules[0].matches[0].path.value == "/api" and .spec.rules[0].filters[0].urlRewrite.path.replacePrefixMatch == "/" and .spec.rules[0].backendRefs[0].name == "api-service"'' "API route must strip the prefix before reaching its backend"}
      ${yq_assert ''select(.kind == "HTTPRoute" and .metadata.name == "web") | .spec.hostnames[0] == "app.example.test" and .spec.parentRefs[0].name == "edge" and .spec.parentRefs[0].sectionName == "http" and .spec.rules[0].matches[0].path.type == "PathPrefix" and .spec.rules[0].matches[0].path.value == "/" and .spec.rules[0].backendRefs[0].name == "web-service"'' "web route must catch all remaining paths on the same hostname and listener"}
      ${yq_assert ''select(.kind == "BackendTrafficPolicy" and .metadata.name == "api-traffic") | .spec.targetRefs[0].name == "api" and .spec.compressor[0].type == "Gzip" and .spec.rateLimit.local.rules[0].limit.requests == 10'' "traffic policy must apply compression and rate limiting to the API"}
      # Validate the example's Gateway/Envoy resources against the pinned CRDs.
      example_rendered="$rendered"
      rendered="$(${pkgs.coreutils}/bin/mktemp --suffix=.yaml)"
      ${yq} 'select(.apiVersion == "gateway.networking.k8s.io/v1" or .apiVersion == "gateway.envoyproxy.io/v1alpha1")' "$example_rendered" > "$rendered"
      ${schemaCheck}
      rm -f "$rendered"
      rendered="$example_rendered"
    '';
  }
  {
    name = "gateway-api-invalid-rewrite";
    suites = [ "fast" ];
    spec = ''hex.toYAMLDoc (hex.k8s.gateway-api.filters.rewrite { replaceFullPath = "/"; replacePrefixMatch = "/"; })'';
    expectFailure = "gateway-api: choose one path rewrite type";
  }
  {
    name = "envoy-gateway-empty-targets";
    suites = [ "fast" ];
    spec = ''hex.k8s.envoy-gateway.security_policy.build { name = "bad"; targetRefs = []; spec = {}; }'';
    expectFailure = "envoy-gateway: a policy needs at least one targetRef";
  }
  {
    name = "envoy-gateway-invalid-compressor";
    suites = [ "fast" ];
    spec = ''hex.toYAMLDoc (hex.k8s.envoy-gateway.traffic.compress [ "invalid" ])'';
    expectFailure = "envoy-gateway: unsupported compressor";
  }
]
