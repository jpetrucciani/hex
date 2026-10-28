# more examples

## graceful shutdown with a `preStop` command

The Pod's termination grace period covers both the `preStop` hook and the
application's normal shutdown. Give the hook a bounded amount of work so the
application still has time to handle `SIGTERM` and exit cleanly.

```nix
{ hex }:
let
  actions = hex.k8s.services.actions;
  labels = { app = "api"; };
in
hex [
  (hex.k8s.services.build {
    name = "api";
    inherit labels;
    image = "ghcr.io/example/api:latest";
    port = 8080;

    terminationGracePeriodSeconds = 60;
    lifecycle.preStop = actions.exec [
      "/app/bin/drain"
      "--deadline=45s"
    ];
  })
]
```

`actions.exec` takes an argument vector and does not run through a shell. If a
hook needs shell syntax, invoke the shell explicitly:

```nix
lifecycle.preStop = actions.exec [
  "/bin/sh"
  "-c"
  "/app/bin/drain && /app/bin/flush"
];
```

Keep shutdown hooks idempotent and treat the grace period as a total budget, not
as extra time granted after the hook completes.

## delay shutdown with the Kubernetes sleep handler

For applications that need a short drain window before receiving `SIGTERM`, use
the native sleep lifecycle action:

```nix
terminationGracePeriodSeconds = 45;
lifecycle.preStop = hex.k8s.services.actions.sleep 10;
```

Here, the process has at most the remaining 35 seconds to shut down. The sleep
handler requires a Kubernetes version that supports the
[`sleep` lifecycle action](https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/).

## protect a slow-starting application

A startup probe prevents Kubernetes from running liveness and readiness probes
until the application has started successfully. The action constructors build
the probe mechanism, then normal Kubernetes probe fields can be merged onto it.

```nix
{ hex }:
let
  probes = hex.k8s.services.probes;
  labels = { app = "worker-api"; };
in
hex [
  (hex.k8s.services.build {
    name = "worker-api";
    inherit labels;
    image = "ghcr.io/example/worker-api:latest";
    port = 8080;

    startupProbe = probes.httpGet {
      path = "/healthz";
      port = 8080;
      periodSeconds = 2;
      failureThreshold = 60;
      timeoutSeconds = 1;
    };
    readinessProbe = probes.httpGet {
      path = "/healthz";
      port = 8080;
      periodSeconds = 5;
      failureThreshold = 2;
    };
    livenessProbe = probes.httpGet {
      path = "/healthz";
      port = 8080;
      periodSeconds = 10;
      failureThreshold = 3;
    };
  })
]
```

This example allows startup to take roughly two minutes before Kubernetes
considers it failed. See the Kubernetes
[probe documentation](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
when choosing thresholds for a real workload.

## notify an HTTP endpoint before shutdown

The same HTTP action constructor can be used for lifecycle hooks:

```nix
terminationGracePeriodSeconds = 30;
lifecycle.preStop = hex.k8s.services.actions.httpGet {
  path = "/internal/drain";
  port = 8080;
};
```

The endpoint should complete quickly and leave enough of the grace period for
the process to exit.

## keep replicas available during rollouts and maintenance

Pod disruption budgets, topology spreading, and rollout policy solve different
parts of the same availability problem. Hex derives the PDB and spread
selectors from the service labels, so they cannot silently select a different
workload.

```nix
{ hex }:
let
  services = hex.k8s.services;
  labels = { app = "api"; };
in
hex [
  (services.build {
    name = "api";
    inherit labels;
    image = "ghcr.io/example/api:latest";
    port = 8080;
    replicas = 3;

    disruptionBudget = services.disruptions.maxUnavailable 1;
    topologySpread = [
      (services.spread.zones {
        mode = "hard";
        minDomains = 2;
      })
      (services.spread.nodes {
        mode = "soft";
      })
    ];
    rollout = services.rollouts.rolling {
      maxUnavailable = 0;
      maxSurge = "25%";
      minReadySeconds = 10;
      progressDeadlineSeconds = 600;
    };
  })
]
```

Use `services.disruptions.minAvailable` instead when the application has a
fixed quorum requirement. A disruption budget accepts only one of
`minAvailable` and `maxUnavailable`.

## scale from multiple metrics

The original `autoscale`, `min`, `max`, and `cpuUtilization` arguments remain as
a CPU shorthand. Use `autoscaling.v2` when a workload needs multiple metrics or
explicit scaling behavior:

```nix
let
  scaling = hex.k8s.services.autoscaling;
in
{
  autoscaling = scaling.v2 {
    min = 2;
    max = 10;
    metrics = [
      (scaling.metrics.cpuUtilization 70)
      (scaling.metrics.memoryUtilization 80)
      (scaling.metrics.external {
        name = "queue_depth";
        averageValue = "10";
      })
    ];
    behavior.scaleDown.stabilizationWindowSeconds = 300;
  };
}
```

Hex renders this as an `autoscaling/v2` HPA. Autoscaling is rejected for
DaemonSets because they do not expose the scale behavior required by an HPA.

## add a sidecar and typed volumes

`containers.build` validates the sidecar identity and its lifecycle/probe
fragments. Volume constructors ensure that each volume has exactly one source
and that volume names and main-container mount paths are unique.

```nix
let
  services = hex.k8s.services;
in
{
  sidecars = [
    (services.containers.build {
      name = "metrics";
      image = "ghcr.io/example/metrics:latest";
      envAttrs.METRICS_PORT = "9090";
      readinessProbe = services.probes.tcpSocket {
        port = 9090;
        periodSeconds = 5;
      };
    })
  ];

  volumes = [
    (services.volumes.secret {
      name = "credentials";
      mountPath = "/run/credentials";
      secretName = "api-credentials";
    })
    (services.volumes.projected {
      name = "runtime-config";
      mountPath = "/run/config";
      sources = [
        { configMap.name = "api-config"; }
        { secret.name = "api-secrets"; }
      ];
    })
  ];
}
```

The volume list is mounted into the main container. Sidecars use normal
Kubernetes `volumeMounts` entries when they need one of the same Pod volumes.

## choose one Service exposure mode

The typed exposure API replaces combinations of `nodePort` and `loadBalancer`
booleans with one explicit Service type. Ports are named and validated.

```nix
let
  services = hex.k8s.services;
in
{
  exposure = services.exposures.loadBalancer {
    ports = [
      (services.ports.tcp {
        name = "https";
        port = 443;
        targetPort = 8080;
        appProtocol = "https";
      })
      (services.ports.udp {
        name = "telemetry";
        port = 4317;
      })
    ];
    externalTrafficPolicy = "Local";
    allocateLoadBalancerNodePorts = false;
  };
}
```

Other constructors are `exposures.clusterIP`, `exposures.headless`, and
`exposures.nodePort`. The legacy Service flags remain supported for existing
modules but cannot be combined with `exposure`. If Ingress is also enabled, its
backend uses the first typed Service port.

## add an uncommon PodSpec field

`extraPodSpec` is the escape hatch for PodSpec fields that do not justify a
first-class service option:

```nix
extraPodSpec = {
  priorityClassName = "workload-critical";
  dnsConfig.options = [
    {
      name = "ndots";
      value = "2";
    }
  ];
};
```

It cannot replace fields managed by `services.build`, such as `containers`,
`volumes`, `serviceAccountName`, or `terminationGracePeriodSeconds`. Use the
corresponding first-class option for those fields.

For the complete argument list and the smaller action-constructor reference,
see [`hex.k8s.services.build`](/reference/generated-services-build).

## run a StatefulSet with per-replica storage

`services.stateful.build` takes the same pod arguments as `services.build` and
adds a headless Service, `volumeClaimTemplates`, and StatefulSet rollouts:

```nix
let services = hex.k8s.services; in
services.stateful.build {
  name = "cache";
  labels = { app = "cache"; };
  image = "valkey/valkey:8";
  replicas = 3;
  ports = [ (services.ports.tcp { name = "redis"; port = 6379; }) ];
  claims = [
    (services.claims.build { name = "data"; mountPath = "/data"; storage = "10Gi"; })
  ];
  rollout = services.stateful.rollouts.ordered { partition = 2; };
  disruptionBudget = services.disruptions.maxUnavailable 1;
}
```

The headless Service is `<name>-headless` and is always rendered; pass
`exposure` for a separate client Service. Claims are retained when the
StatefulSet is deleted or scaled down unless `claimRetention` says otherwise.

## run migrations and one-off jobs

`hex.k8s.jobs.fromService` runs a Job with a service's image, env, volumes, and
ServiceAccount. Pass it the same argument set you give `services.build`:

```nix
let
  api = { name = "api"; labels = { app = "api"; }; image = "example/api:1.2.3"; envFrom = [ { secretRef.name = "api"; } ]; };
in
''
  ${hex.k8s.services.build api}
  ${hex.k8s.jobs.fromService api { name = "api-migrate"; command = [ "/app/migrate" ]; }}
''
```

Job pod templates are immutable, so by default the Job name ends with a hash of
its spec: a new image or command creates a new Job instead of failing to apply.
With `hook = "argo-presync"` (or another entry of `hex.k8s.jobs.hooks`) the Job
keeps a stable name and runs as an Argo CD or Helm hook instead. Old hashed Jobs
are not deleted unless you set `ttlSecondsAfterFinished`; a GitOps tool that
still renders the Job will recreate it after the TTL, so keep migrations
idempotent. `hex.k8s.jobs.shell api { }` renders an idle pod with the same
config for `kubectl exec`, and `hex.k8s.jobs.build` takes the arguments directly.

## roll pods when config changes

ConfigMaps and Secrets passed as `configs` are rendered with the workload and
hashed into the pod template's `checksum/config` annotation:

```nix
configs = [
  (services.configs.configMap { name = "api-config"; data."app.toml" = builtins.readFile ./app.toml; })
];
```

## lock down pods and traffic

`services.security.restricted { }` applies a pod and container securityContext
that meets the restricted Pod Security Standard to every container. Your
`securityContext` still overrides the main container's fields. Add an
`emptyDir` for any path the app writes to, or pass
`readOnlyRootFilesystem = false`.

`services.policies` builds `ingressPolicy` and `egressPolicy` rules; an empty
list denies that direction:

```nix
ingressPolicy = [ (services.policies.ingress.fromLabels { labels = { app = "web"; }; ports = [ 8080 ]; }) ];
egressPolicy = [
  (services.policies.egress.dns { })
  (services.policies.egress.toInternet { ports = [ 443 ]; })
];
```

`services.worker` is `services.build` with no Service, container port, or
inbound traffic, for queue consumers and other background processes.

## set up a namespace with guardrails

`hex.k8s.namespaces.build` renders a Namespace with Pod Security Standards
labels. By default it only warns and audits against `restricted`; set
`enforce` to reject pods. `defaultDeny`, `quota`, and `limits` add a
namespace-wide NetworkPolicy, ResourceQuota, and LimitRange:

```nix
hex.k8s.namespaces.build {
  name = "shop";
  enforce = "restricted";
  defaultDeny = [ "Ingress" "Egress" ]; # DNS egress stays open unless dns = null
  quota = { "requests.cpu" = "8"; pods = "50"; };
  limits.defaultRequest = { cpu = "100m"; memory = "128Mi"; };
}
```

Workload NetworkPolicies add to the default deny, so each workload's
`ingressPolicy` and `egressPolicy` become its allow-list. `services.build`
sets an `Unconfined` AppArmor profile by default, which both `baseline` and
`restricted` reject: pass `security = services.security.restricted { }` (or at
least `appArmor = null`) before enforcing either level.

## scrape metrics

`metrics` on `services.build`, `services.worker`, and `services.stateful.build`
renders a prometheus-operator `PodMonitor` for the workload's pods. An integer
`port` adds a container port named `metrics`; a string references an existing
container port by name:

```nix
metrics = services.metrics.scrape {
  port = 9090;
  path = "/metrics";
  interval = "15s";
  monitorLabels.release = "prometheus"; # match your Prometheus podMonitorSelector
  allowFrom = [ (services.policies.ingress.fromNamespaces { namespaces = [ "monitoring" ]; }) ];
};
```

`allowFrom` rules are added to the workload's NetworkPolicy, limited to the
metrics port; workers deny ingress by default, so they need it, and Hex prints
an evaluation warning when they are missing. Pass `warnings = false` to the
builder to silence Hex warnings for that workload. Use
`kind = "PodMonitoring"` for Google Managed Prometheus.
