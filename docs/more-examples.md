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
