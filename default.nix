{ _compat ? import ./flake-compat.nix
, pkgs ? import _compat.inputs.nixpkgs { overlays = [ pog.overlay ]; }  # TODO: document this, or fix it so we don't have to rely on the end user to provide pog in their pkgs
, pog ? import _compat.inputs.pog { }
, system ? pkgs.stdenv.hostPlatform.system
}:
let
  params = { inherit system pkgs; };
  hex = import ./hex params;
  docsIndex = import ./hex/hex/k8s/docs-index.nix { inherit pkgs; };
  deps = import ./hex/hex/deps.nix { inherit pkgs; };
  test =
    let
      heval = "${hex.hex}/bin/hex -r -e";
      mktemp = "${pkgs.coreutils}/bin/mktemp --suffix=.yaml";
      kubernetesVersion = hex.kubernetesValidation.defaultVersion;
      kubeconformSchemaLocation = hex.kubernetesValidation.schemaLocation;
      num_docs = num: ''[ "$num_docs" -ne ${toString num} ] && echo "not the correct number of docs! expected ${toString num}, but got $num_docs" && exit 1'';
      yq_assert = expression: message: ''
        if ! ${pkgs.yq-go}/bin/yq e -e ${pkgs.lib.escapeShellArg expression} "$rendered" >/dev/null; then
          echo ${pkgs.lib.escapeShellArg message} >&2
          exit 1
        fi
      '';
      validate_kubernetes = allowMissingSchemas: ''
        schema_cache="''${KUBECONFORM_CACHE:-''${XDG_CACHE_HOME:-''${HOME:-/tmp}/.cache}/kubeconform}"
        ${pkgs.coreutils}/bin/mkdir -p "$schema_cache"
        if ! ${pkgs.kubeconform}/bin/kubeconform \
          -cache "$schema_cache" \
          ${pkgs.lib.optionalString allowMissingSchemas "-ignore-missing-schemas"} \
          -kubernetes-version ${kubernetesVersion} \
          -schema-location ${pkgs.lib.escapeShellArg kubeconformSchemaLocation} \
          -strict \
          -summary \
          "$rendered"; then
          echo "rendered manifests failed Kubernetes ${kubernetesVersion} schema validation" >&2
          exit 1
        fi
      '';
      workloadTestBase = ''
        name = "lifecycle-test";
        labels = { app = "lifecycle-test"; };
        image = "example.invalid/lifecycle-test:latest";
        networkPolicy = false;
        roleBinding = false;
        serviceAccount = false;
      '';
      serviceTestBase = ''
        ${workloadTestBase}
        service = false;
      '';
      lifecycleTestBase = ''
        ${serviceTestBase}
        autoscale = false;
      '';
      svcTest =
        { name
        , port
        , spec ? "hex.k8s.svc.${name} {}"
        , documents ? 5
        }:
        {
          inherit name spec;
          suites = [ "fast" "services" ];
          allowMissingSchemas = false;
          check = ''
            ${num_docs documents}
            ${yq_assert ''select(.kind == "Deployment") | .metadata.name == "${name}" and .spec.template.spec.containers[0].image != ""'' "${name} did not render its expected Deployment"}
            ${yq_assert ''select(.kind == "Service") | .metadata.name == "${name}-service" and .spec.ports[0].port == ${toString port}'' "${name} did not render its expected Service port"}
          '';
        };
      cliValidationTests = import ./tests/cli-validation.nix { inherit hex pkgs; };
      testSuites = testCase:
        testCase.suites or
          (if pkgs.lib.hasPrefix "service-" testCase.name then
            [ "fast" "services" ]
          else if testCase.name == "cronjob" then
            [ "fast" ]
          else
            [ "charts" ]);
      baseTests = [
        { name = "cronjob"; spec = ''hex.k8s.cron.build {name = "test"; extra={spec.timeZone ="America/Chicago";};}''; check = num_docs 1; }
        {
          name = "service-lifecycle";
          allowMissingSchemas = false;
          spec = ''
            let actions = hex.k8s.services.actions; in
            hex.k8s.services.build {
              ${lifecycleTestBase}
              terminationGracePeriodSeconds = 60;
              lifecycle = {
                postStart = actions.sleep 1;
                preStop = actions.exec [ "/app/bin/drain" "--timeout=45" ];
              };
              startupProbe = actions.httpGet {
                path = "/healthz";
                port = 8080;
              } // {
                failureThreshold = 30;
                periodSeconds = 2;
              };
              extraPodSpec.priorityClassName = "workload-critical";
            }
          '';
          check = ''
            ${num_docs 1}
            ${yq_assert ''.spec.template.spec.terminationGracePeriodSeconds == 60'' "terminationGracePeriodSeconds was not rendered at PodSpec level"}
            ${yq_assert ''(.spec.template.spec.containers[0].lifecycle.preStop.exec.command | length) == 2 and .spec.template.spec.containers[0].lifecycle.preStop.exec.command[0] == "/app/bin/drain" and .spec.template.spec.containers[0].lifecycle.preStop.exec.command[1] == "--timeout=45"'' "preStop exec action was not rendered on the main container"}
            ${yq_assert ''.spec.template.spec.containers[0].lifecycle.postStart.sleep.seconds == 1'' "postStart sleep action was not rendered on the main container"}
            ${yq_assert ''.spec.template.spec.containers[0].startupProbe.httpGet.path == "/healthz" and .spec.template.spec.containers[0].startupProbe.httpGet.port == 8080'' "startupProbe was not rendered on the main container"}
            ${yq_assert ''.spec.template.spec.priorityClassName == "workload-critical"'' "extraPodSpec was not merged into the PodSpec"}
          '';
        }
        {
          name = "service-lifecycle-invalid-handler";
          spec = ''
            let actions = hex.k8s.services.actions; in
            hex.k8s.services.build {
              ${lifecycleTestBase}
              lifecycle.preStop =
                actions.exec [ "/app/bin/drain" ]
                // actions.sleep 1;
            }
          '';
          expectFailure = "lifecycle.preStop must configure exactly one of exec, httpGet, or sleep";
        }
        {
          name = "service-lifecycle-invalid-grace";
          spec = ''
            hex.k8s.services.build {
              ${lifecycleTestBase}
              terminationGracePeriodSeconds = -1;
            }
          '';
          expectFailure = "terminationGracePeriodSeconds must be null or a non-negative integer";
        }
        {
          name = "service-lifecycle-zero-grace";
          spec = ''
            let actions = hex.k8s.services.actions; in
            hex.k8s.services.build {
              ${lifecycleTestBase}
              terminationGracePeriodSeconds = 0;
              lifecycle.preStop = actions.exec [ "/app/bin/drain" ];
            }
          '';
          expectFailure = "lifecycle.preStop cannot be used when terminationGracePeriodSeconds is 0";
        }
        {
          name = "service-lifecycle-invalid-exec";
          spec = ''
            let actions = hex.k8s.services.actions; in
            hex.k8s.services.build {
              ${lifecycleTestBase}
              lifecycle.preStop = actions.exec [ ];
            }
          '';
          expectFailure = "actions.exec: command must be a non-empty list of strings";
        }
        {
          name = "service-lifecycle-pod-spec-collision";
          spec = ''
            hex.k8s.services.build {
              ${lifecycleTestBase}
              extraPodSpec.serviceAccountName = "unexpected";
            }
          '';
          expectFailure = "extraPodSpec cannot replace Hex-managed fields: serviceAccountName";
        }
        {
          name = "service-availability";
          allowMissingSchemas = false;
          spec = ''
            let
              disruptions = hex.k8s.services.disruptions;
              spread = hex.k8s.services.spread;
            in
            hex.k8s.services.build {
              ${lifecycleTestBase}
              replicas = 3;
              disruptionBudget = (disruptions.maxUnavailable 1) // {
                unhealthyPodEvictionPolicy = "AlwaysAllow";
              };
              topologySpread = [
                (spread.zones {
                  mode = "hard";
                  minDomains = 2;
                })
                (spread.nodes { })
              ];
            }
          '';
          check = ''
            ${num_docs 2}
            ${yq_assert ''select(.kind == "Deployment") | .spec.template.spec.topologySpreadConstraints[0].topologyKey == "topology.kubernetes.io/zone" and .spec.template.spec.topologySpreadConstraints[0].whenUnsatisfiable == "DoNotSchedule" and .spec.template.spec.topologySpreadConstraints[0].labelSelector.matchLabels.app == "lifecycle-test"'' "topology spread constraints were not rendered with the workload labels"}
            ${yq_assert ''select(.kind == "PodDisruptionBudget") | .spec.maxUnavailable == 1 and .spec.unhealthyPodEvictionPolicy == "AlwaysAllow" and .spec.selector.matchLabels.app == "lifecycle-test"'' "PodDisruptionBudget was not rendered with the workload selector"}
          '';
        }
        {
          name = "service-sidecars-probes-volumes";
          allowMissingSchemas = false;
          spec = ''
            let
              containers = hex.k8s.services.containers;
              probes = hex.k8s.services.probes;
              volumes = hex.k8s.services.volumes;
            in
            hex.k8s.services.build {
              ${lifecycleTestBase}
              startupProbe = probes.httpGet {
                port = 8080;
                path = "/startup";
                failureThreshold = 30;
                periodSeconds = 2;
              };
              readinessProbe = probes.tcpSocket {
                port = 8080;
                periodSeconds = 5;
              };
              livenessProbe = probes.grpc {
                port = 9090;
                service = "health";
                periodSeconds = 10;
              };
              sidecars = [
                (containers.build {
                  name = "metrics";
                  image = "example.invalid/metrics:latest";
                  envAttrs.METRICS = "true";
                  readinessProbe = probes.exec {
                    command = [ "/bin/check" ];
                    periodSeconds = 5;
                  };
                })
              ];
              volumes = [
                (volumes.secret {
                  name = "credentials";
                  mountPath = "/run/credentials";
                  secretName = "api-credentials";
                })
                (volumes.projected {
                  name = "projected-config";
                  mountPath = "/run/config";
                  sources = [
                    { configMap.name = "api-config"; }
                    { secret.name = "api-secrets"; }
                  ];
                })
              ];
            }
          '';
          check = ''
            ${num_docs 1}
            ${yq_assert ''.spec.template.spec.containers | length == 2 and .spec.template.spec.containers[1].name == "metrics" and .spec.template.spec.containers[1].env[0].name == "METRICS"'' "sidecar container was not rendered"}
            ${yq_assert ''.spec.template.spec.containers[0].startupProbe.httpGet.path == "/startup" and .spec.template.spec.containers[0].readinessProbe.tcpSocket.port == 8080 and .spec.template.spec.containers[0].livenessProbe.grpc.service == "health"'' "probe constructors were not rendered on the main container"}
            ${yq_assert ''.spec.template.spec.containers[1].readinessProbe.exec.command[0] == "/bin/check"'' "sidecar probe was not validated and rendered"}
            ${yq_assert ''.spec.template.spec.volumes[0].secret.secretName == "api-credentials" and .spec.template.spec.volumes[1].projected.sources | length == 2'' "volume constructors were not rendered"}
          '';
        }
        {
          name = "service-rollout-autoscaling";
          allowMissingSchemas = false;
          spec = ''
            let
              scaling = hex.k8s.services.autoscaling;
              rollouts = hex.k8s.services.rollouts;
            in
            hex.k8s.services.build {
              ${serviceTestBase}
              depSuffix = "-workload";
              rollout = rollouts.rolling {
                maxUnavailable = 0;
                maxSurge = "25%";
                minReadySeconds = 10;
                progressDeadlineSeconds = 600;
              };
              autoscaling = scaling.v2 {
                min = 2;
                max = 8;
                metrics = [
                  (scaling.metrics.cpuUtilization 70)
                  (scaling.metrics.external {
                    name = "queue_depth";
                    averageValue = "10";
                  })
                ];
                behavior.scaleDown.stabilizationWindowSeconds = 300;
              };
            }
          '';
          check = ''
            ${num_docs 2}
            ${yq_assert ''select(.kind == "Deployment") | .spec.strategy.rollingUpdate.maxUnavailable == 0 and .spec.strategy.rollingUpdate.maxSurge == "25%" and .spec.minReadySeconds == 10 and .spec.progressDeadlineSeconds == 600'' "rollout policy was not rendered"}
            ${yq_assert ''select(.kind == "HorizontalPodAutoscaler") | .apiVersion == "autoscaling/v2" and .spec.scaleTargetRef.name == "lifecycle-test-workload" and .spec.minReplicas == 2 and .spec.maxReplicas == 8 and (.spec.metrics | length) == 2 and .spec.metrics[1].external.metric.name == "queue_depth" and .spec.behavior.scaleDown.stabilizationWindowSeconds == 300'' "autoscaling/v2 configuration was not rendered"}
          '';
        }
        {
          name = "service-exposure";
          allowMissingSchemas = false;
          spec = ''
            let
              exposures = hex.k8s.services.exposures;
              ports = hex.k8s.services.ports;
            in
            hex.k8s.services.build {
              ${workloadTestBase}
              autoscale = false;
              exposure = exposures.loadBalancer {
                ports = [
                  (ports.tcp {
                    name = "http";
                    port = 443;
                    targetPort = 8080;
                    appProtocol = "https";
                  })
                  (ports.udp {
                    name = "telemetry";
                    port = 4317;
                  })
                ];
                externalTrafficPolicy = "Local";
                internalTrafficPolicy = "Cluster";
                allocateLoadBalancerNodePorts = false;
              };
            }
          '';
          check = ''
            ${num_docs 2}
            ${yq_assert ''select(.kind == "Service") | .spec.type == "LoadBalancer" and .spec.externalTrafficPolicy == "Local" and .spec.allocateLoadBalancerNodePorts == false and (.spec.ports | length) == 2 and .spec.ports[0].targetPort == 8080 and .spec.ports[1].protocol == "UDP"'' "typed Service exposure was not rendered"}
            ${yq_assert ''select(.kind == "Service") | has(.spec.externalIPs) == false'' "typed LoadBalancer exposure unexpectedly emitted legacy externalIPs"}
          '';
        }
        {
          name = "service-invalid-disruption-budget";
          spec = ''
            let disruptions = hex.k8s.services.disruptions; in
            hex.k8s.services.build {
              ${lifecycleTestBase}
              disruptionBudget =
                (disruptions.minAvailable 1)
                // (disruptions.maxUnavailable 1);
            }
          '';
          expectFailure = "disruptionBudget must configure exactly one of minAvailable or maxUnavailable";
        }
        {
          name = "service-invalid-topology-spread";
          spec = ''
            hex.k8s.services.build {
              ${lifecycleTestBase}
              topologySpread = [
                (hex.k8s.services.spread.zones { maxSkew = 0; })
              ];
            }
          '';
          expectFailure = "topologySpread entry requires a positive maxSkew";
        }
        {
          name = "service-invalid-topology-min-domains";
          spec = ''
            hex.k8s.services.build {
              ${lifecycleTestBase}
              topologySpread = [
                (hex.k8s.services.spread.zones {
                  minDomains = 2;
                  mode = "soft";
                })
              ];
            }
          '';
          expectFailure = "topologySpread.minDomains requires hard scheduling";
        }
        {
          name = "service-invalid-sidecar-name";
          spec = ''
            hex.k8s.services.build {
              ${lifecycleTestBase}
              sidecars = [
                (hex.k8s.services.containers.build {
                  name = "lifecycle-test";
                  image = "example.invalid/sidecar:latest";
                })
              ];
            }
          '';
          expectFailure = "container names must be unique";
        }
        {
          name = "service-invalid-probe-handler";
          spec = ''
            let probes = hex.k8s.services.probes; in
            hex.k8s.services.build {
              ${lifecycleTestBase}
              livenessProbe =
                (probes.httpGet { port = 8080; })
                // (probes.tcpSocket { port = 8080; });
            }
          '';
          expectFailure = "livenessProbe must configure exactly one of exec, httpGet, tcpSocket, or grpc";
        }
        {
          name = "service-invalid-readiness-grace";
          spec = ''
            hex.k8s.services.build {
              ${lifecycleTestBase}
              readinessProbe = hex.k8s.services.probes.httpGet {
                port = 8080;
                terminationGracePeriodSeconds = 5;
              };
            }
          '';
          expectFailure = "readinessProbe cannot configure terminationGracePeriodSeconds";
        }
        {
          name = "service-invalid-rollout";
          spec = ''
            hex.k8s.services.build {
              ${lifecycleTestBase}
              rollout = hex.k8s.services.rollouts.rolling {
                maxSurge = 0;
                maxUnavailable = "0%";
              };
            }
          '';
          expectFailure = "rollout maxSurge and maxUnavailable cannot both be zero";
        }
        {
          name = "service-invalid-daemonset-autoscaling";
          spec = ''
            hex.k8s.services.build {
              ${serviceTestBase}
              daemonSet = true;
            }
          '';
          expectFailure = "autoscaling is unsupported for DaemonSet workloads";
        }
        {
          name = "service-invalid-exposure";
          spec = ''
            let ports = hex.k8s.services.ports; in
            hex.k8s.services.build {
              ${workloadTestBase}
              autoscale = false;
              exposure = hex.k8s.services.exposures.clusterIP {
                ports = [
                  (ports.tcp { name = "api"; port = 8080; })
                  (ports.tcp { name = "api"; port = 8081; })
                ];
              };
            }
          '';
          expectFailure = "exposure port names must be unique";
        }
        {
          name = "service-invalid-volume-source";
          spec = ''
            hex.k8s.services.build {
              ${lifecycleTestBase}
              volumes = [
                {
                  name = "invalid";
                  mountPath = "/invalid";
                  pvc = "data";
                  secret = "credentials";
                }
              ];
            }
          '';
          expectFailure = "volume invalid must configure exactly one source";
        }
        (svcTest { name = "github-actions-exporter"; port = 9999; })
        (svcTest { name = "gitlab-ci-pipelines-exporter"; port = 8080; })
        (svcTest {
          name = "haproxy";
          port = 8443;
          spec = ''hex.k8s.svc.haproxy { name = "haproxy"; }'';
        })
        (svcTest { name = "langfuse"; port = 10000; })
        (svcTest {
          name = "litellm";
          port = 4000;
          documents = 6;
        })
        (svcTest {
          name = "lobe-chat";
          port = 3210;
        })
        (svcTest {
          name = "metabase";
          port = 3000;
          spec = ''hex.k8s.svc.metabase { domain = "meme.com"; }'';
        })
        (svcTest {
          name = "pypi";
          port = 10000;
          spec = ''hex.k8s.svc.pypi { s3Bucket = "test-bucket"; }'';
        })
        (svcTest { name = "web-check"; port = 3000; })
        { name = "external-secrets-v0-17-0"; spec = "hex.k8s.external-secrets.version.v0-17-0 {}"; check = num_docs 39; }
        { name = "external-secrets-v0-18-0"; spec = "hex.k8s.external-secrets.version.v0-18-0 {}"; check = num_docs 40; }
        { name = "mimir"; spec = "hex.k8s.grafana.mimir.version.latest {}"; check = num_docs 81; }
        {
          name = "tempo";
          spec = ''hex.k8s.grafana.tempo.version.latest {
            valuesAttrs.ingest.kafka.address = "kafka.kafka.svc.cluster.local:9092";
          }'';
          check = num_docs 24;
        }
        { name = "semaphore"; spec = "hex.k8s.semaphore.version.latest {}"; check = num_docs 9; }
        { name = "netbox"; spec = "hex.k8s.netbox.version.latest {}"; check = num_docs 33; }
        {
          name = "loki";
          spec = ''hex.k8s.grafana.loki.version.latest {
            valuesAttrs.loki = {
              schemaConfig = { configs = [ { from = "2024-04-01"; index = { period = "24h"; prefix = "loki_index_"; }; object_store = "s3"; schema = "v13"; store = "tsdb"; } ]; };
              storage = {type="s3"; bucketNames=let b = "bucket"; in {admin=b;chunks=b;ruler=b;};};
            };
          }'';
          check = num_docs 30;
        }
        { name = "coroot-node-agent"; spec = ''hex.k8s.coroot.node-agent.version.latest {}''; check = num_docs 1; }
        { name = "open-webui"; spec = "hex.k8s.open-webui.version.latest {}"; check = num_docs 14; }
        { name = "cert-manager"; spec = "hex.k8s.cert-manager.version.latest {}"; check = num_docs 44; }
        { name = "argocd"; spec = "hex.k8s.argocd.version.latest {}"; check = num_docs 53; }
        { name = "argo-workflows"; spec = "hex.k8s.argo-workflows.version.latest {}"; check = num_docs 27; }
        { name = "flipt"; spec = "hex.k8s.flipt.version.latest {}"; check = num_docs 5; }
        { name = "livekit"; spec = "hex.k8s.livekit.version.latest {}"; check = num_docs 3; }
        { name = "retool"; spec = ''hex.k8s.retool.version.latest {valuesAttrs = {config.encryptionKey = "meme"; image.tag = "3.284.7-stable";};}''; check = num_docs 16; }
        { name = "sentry-30"; spec = "hex.k8s.sentry.version.v30-4-0 {}"; check = num_docs 101; }
        { name = "sentry-31"; spec = ''hex.k8s.sentry.version.latest { valuesAttrs.user.existingSecret = "user-secret"; }''; check = num_docs 106; }
        { name = "sentry-latest"; spec = ''hex.k8s.sentry.version.latest { valuesAttrs.user.existingSecret = "user-secret"; }''; check = num_docs 98; }
        { name = "redpanda"; spec = "hex.k8s.redpanda.version.latest {}"; check = num_docs 14; }
        { name = "questdb-latest"; spec = "hex.k8s.questdb.version.latest {}"; check = num_docs 5; }
        { name = "questdb-v1-0-17"; spec = "hex.k8s.questdb.version.v1-0-17 {}"; check = num_docs 5; }
        { name = "jupyterhub"; spec = "hex.k8s.jupyterhub.version.v4-3-1 {}"; check = num_docs 30; }
        { name = "prefect-server"; spec = "hex.k8s.prefect.server.version.latest {}"; check = num_docs 8; }
        { name = "prefect-worker"; spec = ''hex.k8s.prefect.worker.version.latest { valuesAttrs.worker = { apiConfig = "selfHostedServer"; config.workPool = "test"; selfHostedServerApiConfig.apiUrl="127.0.0.1"; }; }''; check = num_docs 4; }
        { name = "trino"; spec = ''hex.k8s.trino.trino.version.latest {}''; check = num_docs 10; }
        { name = "trino-gateway"; spec = ''hex.k8s.trino.gateway.version.latest {}''; check = num_docs 6; }
        { name = "nats"; spec = ''hex.k8s.nats.version.latest {}''; check = num_docs 8; }
        { name = "dask"; spec = ''hex.k8s.dask.kubernetes-operator.version.latest {}''; check = num_docs 8; }
        { name = "prometheus-adapter"; spec = ''hex.k8s.prometheus.adapter.version.latest {}''; check = num_docs 11; }
        { name = "prometheus-pushgateway"; spec = ''hex.k8s.prometheus.pushgateway.version.latest {}''; check = num_docs 3; }
        { name = "prometheus-exporters-cloudwatch"; spec = ''hex.k8s.prometheus.exporters.cloudwatch.version.latest {}''; check = num_docs 7; }
        { name = "prometheus-exporters-elasticsearch"; spec = ''hex.k8s.prometheus.exporters.elasticsearch.version.latest {}''; check = num_docs 2; }
        { name = "prometheus-exporters-mongodb"; spec = ''hex.k8s.prometheus.exporters.mongodb.version.latest {}''; check = num_docs 5; }
        { name = "prometheus-exporters-mysql"; spec = ''hex.k8s.prometheus.exporters.mysql.version.latest {}''; check = num_docs 3; }
        { name = "prometheus-exporters-nats"; spec = ''hex.k8s.prometheus.exporters.nats.version.latest {}''; check = num_docs 2; }
        { name = "prometheus-exporters-postgres"; spec = ''hex.k8s.prometheus.exporters.postgres.version.latest { valuesAttrs.config.datasource.passwordSecret = { name = "pg-pass-secret"; key = "PGPASS"; }; }''; check = num_docs 5; }
        { name = "prometheus-exporters-redis"; spec = ''hex.k8s.prometheus.exporters.redis.version.latest {}''; check = num_docs 5; }
        { name = "dremio"; spec = ''hex.k8s.dremio.version.latest {valuesAttrs.distStorage={type="aws"; aws={bucketName= "test"; region="us-east-2";};};}''; check = num_docs 107; }
        { name = "keda"; spec = ''hex.k8s.keda.version.latest {}''; check = num_docs 29; }
      ];
      tests = map
        (testCase: testCase // { suites = testSuites testCase; })
        (cliValidationTests ++ baseTests);
      test_case = x:
        let
          log = text: ''echo "${text}"'';
          expectedFailure = x.expectFailure or null;
          expectedDocuments = x.expectedDocuments or null;
          renderCommand = x.renderCommand or "${heval} ${pkgs.lib.escapeShellArg x.spec}";
        in
        ''
          ${x.name})
            rendered="$(${mktemp})"
            errors="$(${mktemp})"
            # shellcheck disable=SC2064
            trap "rm -f $rendered $errors" EXIT
            ${renderCommand} >$rendered 2>$errors
            exit_code=$?
            ${log "rendered to $rendered"}
            ${log "exit code: $exit_code"}
            ${if expectedFailure == null then ''
              if [ "$exit_code" -ne 0 ]; then
                ${pkgs.coreutils}/bin/cat "$errors" >&2
                exit "$exit_code"
              fi
              if [ -s "$errors" ]; then
                ${pkgs.coreutils}/bin/cat "$errors" >&2
              fi
              num_docs="$(${pkgs.yq-go}/bin/yq e 'document_index + 1' "$rendered" | ${pkgs.coreutils}/bin/tail -n 1)"
              ${log "num docs: $num_docs"}
              ${pkgs.lib.optionalString (expectedDocuments != null) (num_docs expectedDocuments)}
              ${validate_kubernetes (x.allowMissingSchemas or true)}
              ${x.check or ""}
            '' else ''
              if [ "$exit_code" -eq 0 ]; then
                echo "expected evaluation to fail with: ${expectedFailure}" >&2
                exit 1
              fi
              if ! ${pkgs.gnugrep}/bin/grep -F -- ${pkgs.lib.escapeShellArg expectedFailure} "$errors" >/dev/null; then
                echo "evaluation failed without the expected error: ${expectedFailure}" >&2
                ${pkgs.coreutils}/bin/cat "$errors" >&2
                exit 1
              fi
            ''}
            rm -f "$rendered" "$errors"
            exit 0
            ;;
        '';
      test_names = map (x: x.name) tests;
      unique_test_names = pkgs.lib.unique test_names;
      suite_names = [ "fast" "cli" "services" "charts" ];
      configured_suite_names = pkgs.lib.unique (pkgs.lib.concatMap (x: x.suites) tests);
      unknown_suite_names = builtins.filter
        (suite: !(builtins.elem suite suite_names))
        configured_suite_names;
      duplicate_test_names = builtins.filter
        (name: builtins.length (builtins.filter (test_name: test_name == name) test_names) > 1)
        unique_test_names;
      test_names_are_unique = test_names == unique_test_names;
      test_names_for_suite = suite:
        map (x: x.name) (builtins.filter (x: builtins.elem suite x.suites) tests);
      all_test_name_args = pkgs.lib.concatMapStringsSep " " (name: ''"${name}"'') test_names;
      test_name_args_for_suite = suite:
        pkgs.lib.concatMapStringsSep " " (name: ''"${name}"'') (test_names_for_suite suite);
      run_test_cases = pkgs.lib.concatMapStringsSep "\n" test_case tests;
      selected_test_cases = pkgs.lib.concatMapStringsSep "\n"
        (name: ''
          ${name})
            selected_tests+=("${name}")
            ;;
        '')
        test_names;
      available_tests = pkgs.lib.concatStringsSep "," test_names;
      available_suites = pkgs.lib.concatStringsSep "," suite_names;
      selected_suite_cases = pkgs.lib.concatMapStringsSep "\n"
        (suite: ''
          ${suite})
            selected_tests=(${test_name_args_for_suite suite})
            ;;
        '')
        suite_names;
      listed_suites = pkgs.lib.concatMapStringsSep "\n"
        (suite: ''echo "${suite}: ${pkgs.lib.concatStringsSep "," (test_names_for_suite suite)}"'')
        suite_names;
    in
    assert test_names_are_unique || builtins.throw "duplicate test names: ${pkgs.lib.concatStringsSep ", " duplicate_test_names}";
    assert unknown_suite_names == [ ] || builtins.throw "unknown test suites: ${pkgs.lib.concatStringsSep ", " unknown_suite_names}";
    pkgs.writers.writeBashBin "test" ''
      if [ "''${1:-}" = "--run-test" ]; then
        test_name="''${2:-}"
        case "$test_name" in
          ${run_test_cases}
          *)
            echo "unknown test: $test_name" >&2
            echo "available tests: ${available_tests}" >&2
            exit 2
            ;;
        esac
      fi

      if [ "''${1:-}" = "--help" ]; then
        cat <<'EOF'
      Usage: test [--suite SUITE | TEST[,TEST...]] [GNU PARALLEL OPTIONS...]

      With no selection, all tests run. Suites provide fast logical subsets
      without changing the single-derivation test wrapper.

      Options:
        --suite SUITE   run one of: ${available_suites},all
        --list-suites   print each suite and its tests
        --help          print this help
      EOF
        exit 0
      fi

      if [ "''${1:-}" = "--list-suites" ]; then
        ${listed_suites}
        exit 0
      fi

      selected_tests=(${all_test_name_args})

      if [ "''${1:-}" = "--suite" ]; then
        requested_suite="''${2:-}"
        if [ -z "$requested_suite" ]; then
          echo "--suite requires a suite name" >&2
          echo "available suites: ${available_suites},all" >&2
          exit 2
        fi
        shift 2

        case "$requested_suite" in
          all)
            ;;
          ${selected_suite_cases}
          *)
            echo "unknown suite: $requested_suite" >&2
            echo "available suites: ${available_suites},all" >&2
            exit 2
            ;;
        esac
      fi

      if [ "$#" -gt 0 ] && [[ "$1" != -* ]]; then
        requested_tests="$1"
        shift
        selected_tests=()

        IFS=',' read -r -a test_names <<< "$requested_tests"
        for test_name in "''${test_names[@]}"; do
          test_name="$(${pkgs.coreutils}/bin/printf '%s' "$test_name" | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
          [ -z "$test_name" ] && continue

          case "$test_name" in
            ${selected_test_cases}
            *)
              echo "unknown test: $test_name" >&2
              echo "available tests: ${available_tests}" >&2
              exit 2
              ;;
          esac
        done

        if [ "''${#selected_tests[@]}" -eq 0 ]; then
          echo "no tests selected" >&2
          exit 2
        fi
      fi

      ${pkgs.parallel}/bin/parallel \
        --will-cite \
        --keep-order \
        --line-buffer \
        --tagstring $'\033[36m|\033[0m [{}]' \
        "$@" \
        "$0" --run-test {} \
        ::: "''${selected_tests[@]}"
    '';
in
hex // { inherit deps docsIndex test; }
