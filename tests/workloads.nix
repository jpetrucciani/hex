{ yq_assert }:
let
  suites = [ "fast" "services" ];
  base = ''
    name = "store";
    labels = { app = "store"; };
    image = "example.invalid/store:latest";
  '';
  serviceBase = ''
    ${base}
    autoscale = false;
    service = false;
    roleBinding = false;
    serviceAccount = false;
    networkPolicy = false;
  '';
  policyBase = ''
    ${base}
    autoscale = false;
    service = false;
    roleBinding = false;
    serviceAccount = false;
  '';
  app = ''
    {
      name = "api";
      namespace = "shop";
      labels = { app = "api"; };
      image = "example.invalid/api:1.2.3";
      envAttrs.DATABASE_URL = "postgres://store-headless/shop";
      envFrom = [ { secretRef.name = "api-secrets"; } ];
      configs = [ (hex.k8s.services.configs.configMap { name = "api-config"; data.LOG_LEVEL = "info"; }) ];
      cpuRequest = "2";
    }
  '';
  render = test: test // { inherit suites; allowMissingSchemas = false; };
  # PodMonitor and PodMonitoring are CRDs without schemas in the core catalog
  renderWithCrds = test: test // { inherit suites; allowMissingSchemas = true; };
  failure = test: test // { inherit suites; };
in
map render [
  {
    name = "stateful-basic";
    spec = ''
      let services = hex.k8s.services; in
      services.stateful.build {
        ${base}
        namespace = "data";
        replicas = 3;
        podManagementPolicy = "Parallel";
        ports = [
          (services.ports.tcp { name = "client"; port = 6379; })
          (services.ports.tcp { name = "gossip"; port = 16379; })
        ];
        exposure = services.exposures.clusterIP {
          ports = [ (services.ports.tcp { name = "client"; port = 6379; }) ];
        };
        claims = [
          (services.claims.build { name = "data"; mountPath = "/data"; storage = "10Gi"; storageClass = "fast"; })
        ];
        volumes = [ (services.volumes.emptyDir { name = "tmp"; mountPath = "/tmp"; }) ];
        rollout = services.stateful.rollouts.ordered { partition = 1; minReadySeconds = 5; };
        disruptionBudget = services.disruptions.maxUnavailable 1;
        claimRetention.whenDeleted = "Delete";
        configs = [ (services.configs.configMap { name = "store-config"; data."store.conf" = "maxmemory 1gb"; }) ];
        ingressPolicy = [ (services.policies.ingress.fromLabels { labels = { app = "store"; }; }) ];
      }
    '';
    expectedDocuments = 7;
    check = ''
      ${yq_assert ''select(.kind == "StatefulSet") | .metadata.name == "store" and .spec.serviceName == "store-headless" and .spec.replicas == 3 and .spec.podManagementPolicy == "Parallel"'' "StatefulSet identity was not rendered"}
      ${yq_assert ''select(.kind == "StatefulSet") | .spec.volumeClaimTemplates[0].metadata.name == "data" and .spec.volumeClaimTemplates[0].spec.resources.requests.storage == "10Gi" and .spec.volumeClaimTemplates[0].spec.storageClassName == "fast"'' "claim template was not rendered"}
      ${yq_assert ''select(.kind == "StatefulSet") | .spec.template.spec.containers[0].volumeMounts[0].name == "tmp" and .spec.template.spec.containers[0].volumeMounts[1].name == "data" and .spec.template.spec.containers[0].volumeMounts[1].readOnly == false'' "claim was not mounted in the main container"}
      ${yq_assert ''select(.kind == "StatefulSet") | .spec.template.spec.containers[0].ports[1].name == "gossip" and .spec.template.spec.containers[0].ports[1].containerPort == 16379'' "container ports were not derived from the Service ports"}
      ${yq_assert ''select(.kind == "StatefulSet") | .spec.updateStrategy.rollingUpdate.partition == 1 and .spec.minReadySeconds == 5 and .spec.persistentVolumeClaimRetentionPolicy.whenDeleted == "Delete"'' "rollout or claim retention was not rendered"}
      ${yq_assert ''select(.kind == "StatefulSet") | .spec.template.metadata.annotations."checksum/config" | length == 16'' "config hash annotation was not rendered"}
      ${yq_assert ''select(.kind == "StatefulSet") | .spec.template.spec.serviceAccountName == "store-service-account"'' "StatefulSet did not use its ServiceAccount"}
      ${yq_assert ''select(.kind == "Service" and .metadata.name == "store-headless") | .spec.clusterIP == "None" and .spec.publishNotReadyAddresses == true and (.spec.ports | length) == 2'' "headless Service was not rendered"}
      ${yq_assert ''select(.kind == "Service" and .metadata.name == "store-service") | .spec.type == "ClusterIP" and .spec.selector.app == "store"'' "client Service was not rendered"}
      ${yq_assert ''select(.kind == "ConfigMap") | .metadata.namespace == "data" and .data."store.conf" == "maxmemory 1gb"'' "ConfigMap was not rendered in the workload namespace"}
      ${yq_assert ''select(.kind == "PodDisruptionBudget") | .spec.maxUnavailable == 1'' "PodDisruptionBudget was not rendered"}
      ${yq_assert ''select(.kind == "NetworkPolicy") | .spec.ingress[0].from[0].podSelector.matchLabels.app == "store"'' "ingress policy preset was not rendered"}
    '';
  }
  {
    name = "stateful-minimal";
    spec = ''
      hex.k8s.services.stateful.build {
        ${base}
        networkPolicy = false;
        serviceAccount = false;
        rollout = hex.k8s.services.stateful.rollouts.onDelete { };
      }
    '';
    expectedDocuments = 2;
    check = ''
      ${yq_assert ''select(.kind == "StatefulSet") | .spec.replicas == 1 and .spec.updateStrategy.type == "OnDelete" and (.spec | has("volumeClaimTemplates") | not) and .spec.template.spec.serviceAccountName == "default"'' "minimal StatefulSet defaults changed"}
      ${yq_assert ''select(.kind == "Service") | .spec.clusterIP == "None" and (.spec | has("ports") | not)'' "headless Service without ports was not rendered"}
    '';
  }
  {
    name = "jobs-build";
    spec = ''
      hex.k8s.jobs.build {
        name = "backfill";
        namespace = "batch";
        image = "example.invalid/backfill:1";
        command = [ "/app/backfill" ];
        completions = 4;
        parallelism = 2;
        completionMode = "Indexed";
        ttlSecondsAfterFinished = 3600;
        podFailurePolicy.rules = [ { action = "FailJob"; onExitCodes = { operator = "In"; values = [ 42 ]; }; } ];
        roleRules = [ { apiGroups = [ "" ]; resources = [ "configmaps" ]; verbs = [ "get" ]; } ];
      }
    '';
    expectedDocuments = 4;
    check = ''
      ${yq_assert ''select(.kind == "Job") | .metadata.name | test("^backfill-[0-9a-f]{8}$")'' "Job name was not suffixed with a spec hash"}
      ${yq_assert ''select(.kind == "Job") | .spec.completionMode == "Indexed" and .spec.completions == 4 and .spec.parallelism == 2 and .spec.backoffLimit == 3 and .spec.ttlSecondsAfterFinished == 3600'' "Job spec fields were not rendered"}
      ${yq_assert ''select(.kind == "Job") | .spec.template.spec.restartPolicy == "Never" and .spec.template.spec.serviceAccountName == "backfill-sa" and .spec.template.metadata.labels.app == "backfill"'' "Job pod defaults changed"}
      ${yq_assert ''select(.kind == "Job") | .spec.podFailurePolicy.rules[0].action == "FailJob"'' "podFailurePolicy was not rendered"}
      ${yq_assert ''select(.kind == "RoleBinding") | .roleRef.name == "backfill-role" and .subjects[0].name == "backfill-sa"'' "Job RBAC was not bound to its ServiceAccount"}
    '';
  }
  {
    name = "jobs-hook";
    spec = ''
      hex.k8s.jobs.build {
        name = "migrate";
        image = "example.invalid/api:1";
        command = [ "/app/migrate" ];
        hook = "argo-presync";
        serviceAccount = false;
      }
    '';
    expectedDocuments = 1;
    check = ''
      ${yq_assert ''.metadata.name == "migrate" and .metadata.annotations."argocd.argoproj.io/hook" == "PreSync" and .metadata.annotations."argocd.argoproj.io/hook-delete-policy" == "BeforeHookCreation"'' "Argo CD hook Job was not rendered with a stable name"}
    '';
  }
  {
    name = "jobs-from-service";
    spec = ''
      let
        app = ${app};
        job = hex.k8s.jobs.fromService app { name = "api-migrate"; command = [ "/app/migrate" ]; };
        changed = hex.k8s.jobs.fromService (app // { image = "example.invalid/api:1.2.4"; }) { name = "api-migrate"; command = [ "/app/migrate" ]; };
      in
      assert job != changed;
      job
    '';
    expectedDocuments = 1;
    check = ''
      ${yq_assert ''.metadata.namespace == "shop" and .spec.template.spec.containers[0].image == "example.invalid/api:1.2.3"'' "Job did not inherit the service image and namespace"}
      ${yq_assert ''.spec.template.spec.serviceAccountName == "api-service-account" and .spec.template.spec.containers[0].envFrom[0].secretRef.name == "api-secrets" and .spec.template.spec.containers[0].env[0].name == "DATABASE_URL"'' "Job did not inherit the service ServiceAccount and env"}
      ${yq_assert ''.spec.template.metadata.labels.app == "api-migrate" and .spec.template.spec.containers[0].resources.requests.cpu == "100m"'' "Job reused service labels or resources"}
      ${yq_assert ''.spec.template.metadata.annotations."checksum/config" | length == 16'' "Job did not carry the service config hash"}
    '';
  }
  {
    name = "jobs-shell";
    spec = ''hex.k8s.jobs.shell ${app} { }'';
    expectedDocuments = 1;
    check = ''
      ${yq_assert ''.metadata.name == "api-shell" and .spec.activeDeadlineSeconds == 14400 and .spec.backoffLimit == 0 and .spec.template.spec.containers[0].command[0] == "tail"'' "debug shell Job was not rendered"}
    '';
  }
  {
    name = "service-configs";
    spec = ''
      let
        services = hex.k8s.services;
        config = value: services.configs.configMap { name = "store-config"; data.mode = value; };
      in
      assert services.configs.hash [ (config "a") ] != services.configs.hash [ (config "b") ];
      services.build {
        ${serviceBase}
        namespace = "shop";
        configs = [
          (config "a")
          (services.configs.secret { name = "store-secret"; stringData.TOKEN = "demo"; })
        ];
      }
    '';
    expectedDocuments = 3;
    check = ''
      ${yq_assert ''select(.kind == "ConfigMap") | .metadata.namespace == "shop" and .data.mode == "a"'' "ConfigMap was not rendered"}
      ${yq_assert ''select(.kind == "Secret") | .type == "Opaque" and .stringData.TOKEN == "demo"'' "Secret was not rendered"}
      ${yq_assert ''select(.kind == "Deployment") | .spec.template.metadata.annotations."checksum/config" | length == 16'' "config hash annotation was not rendered"}
    '';
  }
  {
    name = "service-security-restricted";
    spec = ''
      let services = hex.k8s.services; in
      services.build {
        ${serviceBase}
        security = services.security.restricted { fsGroup = 2000; };
        securityContext.readOnlyRootFilesystem = false;
        initContainers = [ { name = "init"; image = "example.invalid/init:1"; } ];
        sidecars = [ (services.containers.build { name = "proxy"; image = "example.invalid/proxy:1"; }) ];
      }
    '';
    expectedDocuments = 1;
    check = ''
      ${yq_assert ''.spec.template.spec.securityContext.runAsNonRoot == true and .spec.template.spec.securityContext.runAsUser == 65532 and .spec.template.spec.securityContext.fsGroup == 2000 and .spec.template.spec.securityContext.seccompProfile.type == "RuntimeDefault" and .spec.template.spec.securityContext.appArmorProfile.type == "RuntimeDefault"'' "restricted pod securityContext was not rendered"}
      ${yq_assert ''[.spec.template.spec.containers[], .spec.template.spec.initContainers[]] | all_c(.securityContext.allowPrivilegeEscalation == false and .securityContext.capabilities.drop[0] == "ALL")'' "restricted container securityContext was not applied to every container"}
      ${yq_assert ''.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem == false and .spec.template.spec.containers[1].securityContext.readOnlyRootFilesystem == true'' "main container securityContext did not override the profile"}
      ${yq_assert ''.spec.template.spec.containers[0].securityContext | has("appArmorProfile") | not'' "restricted profile still set the Unconfined AppArmor override"}
    '';
  }
  {
    name = "service-policies";
    spec = ''
      let p = hex.k8s.services.policies; in
      hex.k8s.services.build {
        ${policyBase}
        ingressPolicy = [
          (p.ingress.fromLabels { labels = { app = "web"; }; namespaces = [ "frontend" ]; ports = [ 8080 ]; })
          (p.ingress.fromNamespace { })
        ];
        egressPolicy = [
          (p.egress.dns { })
          (p.egress.toInternet { ports = [ 443 ]; })
          (p.egress.toCidr { cidr = "10.20.0.0/16"; ports = [ { port = 5432; } ]; })
        ];
      }
    '';
    expectedDocuments = 2;
    check = ''
      ${yq_assert ''select(.kind == "NetworkPolicy") | .spec.ingress[0].from[0].podSelector.matchLabels.app == "web" and .spec.ingress[0].from[0].namespaceSelector.matchExpressions[0].values[0] == "frontend" and .spec.ingress[0].ports[0].port == 8080 and .spec.ingress[0].ports[0].protocol == "TCP"'' "fromLabels ingress rule was not rendered"}
      ${yq_assert ''select(.kind == "NetworkPolicy") | (.spec.ingress[1].from[0].podSelector | length) == 0'' "fromNamespace ingress rule was not rendered"}
      ${yq_assert ''select(.kind == "NetworkPolicy") | .spec.egress[0].to[0].namespaceSelector.matchExpressions[0].values[0] == "kube-system" and .spec.egress[0].to[0].podSelector.matchLabels."k8s-app" == "kube-dns" and (.spec.egress[0].ports | length) == 2'' "DNS egress rule was not rendered"}
      ${yq_assert ''select(.kind == "NetworkPolicy") | .spec.egress[1].to[0].ipBlock.except[0] == "10.0.0.0/8" and .spec.egress[2].to[0].ipBlock.cidr == "10.20.0.0/16"'' "CIDR egress rules were not rendered"}
    '';
  }
  {
    name = "service-worker";
    spec = ''
      hex.k8s.services.worker {
        ${base}
        roleBinding = false;
        autoscale = false;
      }
    '';
    expectedDocuments = 3;
    check = ''
      ${yq_assert ''select(.kind == "Deployment") | .spec.template.spec.containers[0] | has("ports") | not'' "worker exposed a container port"}
      ${yq_assert ''select(.kind == "NetworkPolicy") | (.spec | has("ingress") | not) and .spec.policyTypes[0] == "Ingress" and .spec.egress[0].to[0].ipBlock.cidr == "0.0.0.0/0"'' "worker did not deny ingress by omitting its rules"}
      ${yq_assert ''[select(.kind == "Service")] | length == 0'' "worker rendered a Service"}
    '';
  }
  {
    name = "cronjob-labels-security";
    spec = ''
      hex.k8s.cron.build {
        name = "report";
        labels = { app = "report"; };
        backoffLimit = 1;
        security = hex.k8s.services.security.restricted { };
        volumes = [ (hex.k8s.services.volumes.emptyDir { name = "tmp"; mountPath = "/tmp"; }) ];
      }
    '';
    expectedDocuments = 1;
    check = ''
      ${yq_assert ''.metadata.labels.app == "report" and .spec.jobTemplate.spec.backoffLimit == 1 and .spec.jobTemplate.spec.template.metadata.labels.app == "report"'' "CronJob labels or job spec were not rendered"}
      ${yq_assert ''.spec.jobTemplate.spec.template.spec.securityContext.runAsNonRoot == true and .spec.jobTemplate.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation == false'' "CronJob security profile was not applied"}
      ${yq_assert ''(.spec.jobTemplate.spec.template.spec.volumes[0].emptyDir | length) == 0 and .spec.jobTemplate.spec.template.spec.containers[0].env[2].name == "HEX"'' "CronJob volumes or default env changed"}
    '';
  }
  {
    name = "cronjob-kube-ttl";
    spec = ''hex.k8s.cron.kube_cron.build { name = "cleanup"; ttlSecondsAfterFinished = 600; }'';
    expectedDocuments = 4;
    check = ''
      ${yq_assert ''select(.kind == "CronJob") | .spec.jobTemplate.spec.ttlSecondsAfterFinished == 600 and .spec.jobTemplate.spec.template.spec.serviceAccountName == "cleanup-sa"'' "kube_cron job spec options were not rendered"}
    '';
  }
  {
    name = "example-ledger";
    spec = ''import ${../examples/ledger.nix} { inherit hex; }'';
    expectedDocuments = 11;
    check = ''
      ${yq_assert ''select(.kind == "StatefulSet") | .metadata.namespace == "ledger" and .spec.template.spec.securityContext.fsGroup == 70 and .spec.template.spec.containers[0].volumeMounts[2].mountPath == "/var/lib/postgresql/data"'' "example Postgres StatefulSet changed"}
      ${yq_assert ''select(.kind == "Job") | .metadata.name | test("^ledger-migrate-[0-9a-f]{8}$")'' "example migration Job is not content-addressed"}
      ${yq_assert ''select(.kind == "Job") | .spec.template.spec.serviceAccountName == "ledger-worker-service-account" and .spec.template.spec.volumes[0].configMap.name == "ledger-migrations"'' "example migration Job did not inherit the worker config"}
      ${yq_assert ''select(.kind == "NetworkPolicy" and .metadata.name == "ledger-db-policy") | .spec.ingress[0].from[0].podSelector.matchLabels."app.kubernetes.io/part-of" == "ledger" and (.spec | has("egress") | not)'' "example database NetworkPolicy changed"}
    '';
  }
  {
    name = "namespace-guardrails";
    spec = ''
      hex.k8s.namespaces.build {
        name = "shop";
        labels.team = "payments";
        enforce = "restricted";
        podSecurityVersion = "v1.33";
        defaultDeny = [ "Ingress" "Egress" ];
        quota = { "requests.cpu" = "8"; pods = "50"; };
        limits.defaultRequest = { cpu = "100m"; memory = "128Mi"; };
      }
    '';
    expectedDocuments = 4;
    check = ''
      ${yq_assert ''select(.kind == "Namespace") | .metadata.labels.team == "payments" and .metadata.labels."pod-security.kubernetes.io/enforce" == "restricted" and .metadata.labels."pod-security.kubernetes.io/audit-version" == "v1.33"'' "Pod Security labels were not rendered"}
      ${yq_assert ''select(.kind == "NetworkPolicy") | .metadata.namespace == "shop" and (.spec.podSelector | length) == 0 and (.spec.policyTypes | length) == 2 and (.spec | has("ingress") | not) and .spec.egress[0].ports[0].port == 53'' "default-deny policy did not keep only DNS egress"}
      ${yq_assert ''select(.kind == "ResourceQuota") | .spec.hard.pods == "50"'' "ResourceQuota was not rendered"}
      ${yq_assert ''select(.kind == "LimitRange") | .spec.limits[0].type == "Container" and .spec.limits[0].defaultRequest.cpu == "100m"'' "LimitRange was not rendered"}
    '';
  }
  {
    name = "namespace-minimal";
    spec = ''hex.k8s.namespaces.build { name = "sandbox"; }'';
    expectedDocuments = 1;
    check = ''
      ${yq_assert ''.metadata.labels."pod-security.kubernetes.io/warn" == "restricted" and .metadata.labels."pod-security.kubernetes.io/audit" == "restricted" and (.metadata.labels | has("pod-security.kubernetes.io/enforce") | not)'' "namespace did not default to warn and audit only"}
    '';
  }
]
++ map renderWithCrds [
  {
    name = "service-worker-metrics";
    spec = ''
      let services = hex.k8s.services; in
      services.worker {
        ${base}
        roleBinding = false;
        autoscale = false;
        metrics = services.metrics.scrape {
          port = 9090;
          interval = "15s";
          monitorLabels.release = "prometheus";
          allowFrom = [ (services.policies.ingress.fromNamespaces { namespaces = [ "monitoring" ]; }) ];
        };
      }
    '';
    expectedDocuments = 4;
    expectNoWarning = "nothing can scrape them";
    check = ''
      ${yq_assert ''select(.kind == "Deployment") | .spec.template.spec.containers[0].ports[0].name == "metrics" and .spec.template.spec.containers[0].ports[0].containerPort == 9090'' "metrics port was not added to the container"}
      ${yq_assert ''select(.kind == "PodMonitor") | .apiVersion == "monitoring.coreos.com/v1" and .metadata.labels.release == "prometheus" and .spec.selector.matchLabels.app == "store" and .spec.podMetricsEndpoints[0].port == "metrics" and .spec.podMetricsEndpoints[0].interval == "15s" and .spec.podMetricsEndpoints[0].path == "/metrics"'' "PodMonitor was not rendered"}
      ${yq_assert ''select(.kind == "NetworkPolicy") | (.spec.ingress | length) == 1 and .spec.ingress[0].ports[0].port == "metrics" and .spec.ingress[0].from[0].namespaceSelector.matchExpressions[0].values[0] == "monitoring"'' "scraper was not allowed to reach the metrics port"}
    '';
  }
  {
    name = "service-worker-metrics-unreachable";
    spec = ''hex.k8s.services.worker { ${base} autoscale = false; metrics = hex.k8s.services.metrics.scrape { port = 9090; }; }'';
    expectWarning = "metrics are set but the NetworkPolicy denies all ingress, so nothing can scrape them";
  }
  {
    name = "service-worker-metrics-warnings-off";
    spec = ''hex.k8s.services.worker { ${base} autoscale = false; warnings = false; metrics = hex.k8s.services.metrics.scrape { port = 9090; }; }'';
    expectNoWarning = "nothing can scrape them";
  }
  {
    name = "stateful-metrics-gmp";
    spec = ''
      let services = hex.k8s.services; in
      services.stateful.build {
        ${base}
        serviceAccount = false;
        networkPolicy = false;
        ports = [ (services.ports.tcp { name = "exporter"; port = 9121; }) ];
        metrics = services.metrics.scrape { port = "exporter"; kind = "PodMonitoring"; scrapeTimeout = "10s"; };
      }
    '';
    expectedDocuments = 3;
    check = ''
      ${yq_assert ''select(.kind == "StatefulSet") | (.spec.template.spec.containers[0].ports | length) == 1'' "a named metrics port added a duplicate container port"}
      ${yq_assert ''select(.kind == "PodMonitoring") | .apiVersion == "monitoring.googleapis.com/v1" and .spec.endpoints[0].port == "exporter" and .spec.endpoints[0].timeout == "10s"'' "PodMonitoring was not rendered"}
    '';
  }
]
++ map failure [
  {
    name = "namespace-invalid-level";
    spec = ''hex.k8s.namespaces.build { name = "shop"; enforce = "strict"; }'';
    expectFailure = "enforce, warn, and audit must be null, privileged, baseline, or restricted";
  }
  {
    name = "namespace-invalid-deny";
    spec = ''hex.k8s.namespaces.build { name = "shop"; defaultDeny = [ "All" ]; }'';
    expectFailure = "defaultDeny must be a list of unique Ingress or Egress entries";
  }
  {
    name = "service-invalid-metrics-port-name";
    spec = ''hex.k8s.services.worker { ${base} metrics = hex.k8s.services.metrics.scrape { port = "prom"; }; }'';
    expectFailure = "is not a container port name";
  }
  {
    name = "service-invalid-metrics-port-collision";
    spec = ''hex.k8s.services.build { ${serviceBase} port = 8080; metrics = hex.k8s.services.metrics.scrape { port = 8080; }; }'';
    expectFailure = "is already a container port; reference it by name instead";
  }
  {
    name = "service-invalid-probe-port";
    spec = ''hex.k8s.services.build { ${serviceBase} port = 8080; readinessProbe = hex.k8s.services.probes.httpGet { port = "web"; }; }'';
    expectFailure = "probes reference ports the container does not expose: web";
  }
  {
    name = "service-invalid-limit-below-request";
    spec = ''hex.k8s.services.build { ${serviceBase} memoryRequest = "1Gi"; memoryLimit = "512Mi"; cpuRequest = "1.5"; cpuLimit = "1500m"; }'';
    expectFailure = "limits must be at least their requests: memory limit 512Mi < request 1Gi";
  }
  {
    name = "service-invalid-metrics-interval";
    spec = ''hex.k8s.services.metrics.scrape { port = 9090; interval = "30"; }'';
    expectFailure = "interval must be a duration";
  }
  {
    name = "stateful-invalid-claim-retention";
    spec = ''hex.k8s.services.stateful.build { ${base} claimRetention.whenDeleted = "Keep"; }'';
    expectFailure = "claimRetention values must be Delete or Retain";
  }
  {
    name = "stateful-invalid-claim-name";
    spec = ''
      let services = hex.k8s.services; in
      services.stateful.build {
        ${base}
        claims = [ (services.claims.build { name = "data"; mountPath = "/data"; storage = "1Gi"; }) ];
        volumes = [ (services.volumes.emptyDir { name = "data"; mountPath = "/scratch"; }) ];
      }
    '';
    expectFailure = "hex.k8s.services.stateful.build: volume names must be unique";
  }
  {
    name = "stateful-invalid-claim-access-mode";
    spec = ''hex.k8s.services.stateful.build { ${base} claims = [ (hex.k8s.services.claims.build { name = "data"; mountPath = "/data"; storage = "1Gi"; accessModes = [ "ReadWriteSometimes" ]; }) ]; }'';
    expectFailure = "accessModes must be a non-empty list";
  }
  {
    name = "stateful-invalid-deployment-rollout";
    spec = ''hex.k8s.services.stateful.build { ${base} rollout = hex.k8s.services.rollouts.recreate { }; }'';
    expectFailure = "rollout must come from services.stateful.rollouts";
  }
  {
    name = "jobs-invalid-hook";
    spec = ''hex.k8s.jobs.build { name = "x"; image = "example.invalid/x:1"; hook = "flux-presync"; }'';
    expectFailure = "hook must be null or one of";
  }
  {
    name = "jobs-invalid-pod-failure-policy";
    spec = ''hex.k8s.jobs.build { name = "x"; image = "example.invalid/x:1"; restartPolicy = "OnFailure"; podFailurePolicy.rules = [ ]; }'';
    expectFailure = "podFailurePolicy requires restartPolicy = Never";
  }
  {
    name = "jobs-invalid-indexed";
    spec = ''hex.k8s.jobs.build { name = "x"; image = "example.invalid/x:1"; completionMode = "Indexed"; }'';
    expectFailure = "Indexed completionMode requires completions";
  }
  {
    name = "jobs-invalid-name-length";
    spec = ''hex.k8s.jobs.build { name = "a-very-long-migration-job-name-that-will-not-fit-with-a-hash"; image = "example.invalid/x:1"; }'';
    expectFailure = "must be at most 63 characters";
  }
  {
    name = "service-invalid-security-tailscale";
    spec = ''hex.k8s.services.build { ${serviceBase} tailscaleSidecar = true; security = hex.k8s.services.security.restricted { }; }'';
    expectFailure = "security profiles cannot be combined with tailscaleSidecar";
  }
  {
    name = "service-invalid-policy-rule";
    spec = ''hex.k8s.services.build { ${policyBase} ingressPolicy = [ { to = [ ]; } ]; }'';
    expectFailure = "ingressPolicy rules may only contain from and ports";
  }
  {
    name = "service-invalid-configs";
    spec = ''
      let c = hex.k8s.services.configs.configMap { name = "dup"; }; in
      hex.k8s.services.build { ${serviceBase} configs = [ c c ]; }
    '';
    expectFailure = "configs must have unique kind and name pairs";
  }
  {
    name = "service-invalid-worker-port";
    spec = ''hex.k8s.services.worker { ${base} port = 8080; }'';
    expectFailure = "workers do not expose endpoints; remove port";
  }
]
