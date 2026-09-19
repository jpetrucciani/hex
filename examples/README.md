# Runnable Hex examples

Keep examples as complete `.nix` spells that can be rendered with Hex. Each should
include its demo workloads, document prerequisites and expected behavior, and
have a render test using the example file itself.

| Example | Demonstrates |
| --- | --- |
| [envoy-gateway.nix](envoy-gateway.nix) | Controller installation, one hostname with API/web path routing, headers, compression and rate limiting |

## Envoy Gateway

This example installs Envoy Gateway 1.9.1 and its CRDs, creates an HTTP Gateway,
and deploys two [whoami echo servers](https://github.com/traefik/whoami) in
`envoy-example`. The managed Envoy Service is ClusterIP, accessed through a local
port-forward. No DNS records, TLS Secrets or load balancer are needed.

Both routes use `app.example.test`: `/api` and `/api/*` reach the API deployment;
everything else reaches the web deployment. The small wrapper in the example
sets the shared hostname, Gateway and headers, leaving the split as:

```nix
(route { name = "web"; }) # defaults to PathPrefix "/"
(route {
  name = "api";
  path = "/api";
  filters = [ g.filters.strip_prefix ];
})
```

Gateway API selects the longest matching prefix across routes, so `/api` wins
over `/` regardless of declaration order. Prefixes match whole path segments:
`/apix` reaches web. Keeping separate HTTPRoute resources lets the compression
and rate-limit policy target only the API route. To retain `/api` in the upstream
request, omit `strip_prefix`.

Use a test cluster with a Kubernetes release supported by Envoy Gateway 1.9.1.
The controller and CRDs are cluster infrastructure; if Envoy Gateway or Gateway
API CRDs are already installed, reuse those and remove the chart line from the
example as appropriate.

### Render and install

Run from the repository root. `path:.` includes local, untracked example files.
`--render` only writes manifests; the `kubectl` commands below install them in
your current context.

```bash
nix run path:.#hex -- --render -t examples/envoy-gateway.nix > /tmp/hex-envoy-example.yaml

# Establish CRDs before submitting resources that use them.
yq 'select(.kind == "CustomResourceDefinition")' /tmp/hex-envoy-example.yaml > /tmp/hex-envoy-example-crds.yaml
kubectl apply --server-side -f /tmp/hex-envoy-example-crds.yaml
kubectl wait --for=condition=Established --timeout=120s -f /tmp/hex-envoy-example-crds.yaml
kubectl apply --server-side -f /tmp/hex-envoy-example.yaml

kubectl -n envoy-gateway-system rollout status deployment/envoy-gateway --timeout=120s
kubectl -n envoy-example rollout status deployment/web --timeout=120s
kubectl -n envoy-example rollout status deployment/api --timeout=120s
kubectl -n envoy-example wait --for=condition=Programmed gateway/edge --timeout=120s
```

`yq` here is the Go-based `mikefarah/yq`. Server-side apply avoids the annotation
size limit for large CRDs. The complete rendered file also includes the chart's
controller namespace and certificate-generation Job.

### Try the routes

Discover the Service created by the controller and keep this port-forward running:

```bash
envoy_service=$(kubectl -n envoy-gateway-system get service \
  -l gateway.envoyproxy.io/owning-gateway-name=edge,gateway.envoyproxy.io/owning-gateway-namespace=envoy-example \
  -o jsonpath='{.items[0].metadata.name}')
kubectl -n envoy-gateway-system port-forward "service/$envoy_service" 8080:80
```

In another terminal:

```bash
curl -i -H 'Host: app.example.test' http://localhost:8080/hello
curl -i --compressed -H 'Host: app.example.test' http://localhost:8080/api/hello
curl -i -H 'Host: app.example.test' http://localhost:8080/apix
```

| Request | What to look for |
| --- | --- |
| `app.example.test/hello` | Echoed `GET /hello`, injected `X-Example-Gateway: hex`, response header `X-Example-Route: web` |
| `app.example.test/api/hello` | Echoed `GET /hello` after stripping `/api`, response header `X-Example-Route: api`, gzip negotiated with `--compressed` |
| `app.example.test/api` | API backend receives `/` |
| `app.example.test/apix` | Web backend receives `/apix`; this is not an `/api` path segment |

The API route also allows 10 requests per second per Envoy instance; excess
requests receive 429 responses. The web route has no rate-limit policy.

Header changes and path rewriting are Gateway API **filters**, composed into
`HTTPRoute` rules. Compression and rate limiting are Envoy **policy** fields,
composed into a `BackendTrafficPolicy` targeting the API route.

### Cleanup

Remove just the demo resources, leaving the shared controller and CRDs installed:

```bash
kubectl delete namespace envoy-example
kubectl delete gatewayclass envoy-example
```

See the [Envoy Gateway guide](../docs/integration-envoy-gateway.md) for HTTPS,
IP allowlists, authentication and cross-namespace routing. The example's CI check
covers rendering and schema validation, not installation or live HTTP behavior.
