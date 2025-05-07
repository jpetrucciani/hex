{ hex, pkgs, ... }:
{ name ? "langfuse"
, namespace ? "default"
, image_base ? "langfuse/langfuse"
, image_tag ? "3.52.0"
, image ? "${image_base}:${image_tag}"
, replicas ? 1
, cpuRequest ? "0.2"
, cpuLimit ? "1"
, memoryRequest ? "1Gi"
, memoryLimit ? "4Gi"
, autoscale ? false
, extraEnv ? [ ]
, extraEnvAttrs ? { }
, port ? 10000
, secretName ? "langfuse-secret"
, readinessProbe ? null
, maxUnavailable ? 0
, maxSurge ? "50%"
, labels ? {
    inherit name;
    tier = "infra";
  }
, extraService ? { } # escape hatch to inject other service spec
  # langfuse specific
, telemetryEnabled ? false
, experimentalFeatures ? true
, extraDeploymentAnnotations ? { }
}:
let
  inherit (pkgs.lib) recursiveUpdate;
  volumes = [ hex.k8s.services.components.volumes.tmp ];
  # other env settings can be found here: https://github.com/langfuse/langfuse/blob/main/docker-compose.yml
in
hex.k8s.services.build (recursiveUpdate
{
  inherit name namespace labels port image replicas cpuRequest cpuLimit memoryRequest memoryLimit autoscale volumes readinessProbe maxUnavailable maxSurge extraDeploymentAnnotations;
  envAttrs = {
    LANGFUSE_ENABLE_EXPERIMENTAL_FEATURES = hex.boolToString experimentalFeatures;
    TELEMETRY_ENABLED = hex.boolToString telemetryEnabled;
    PORT = toString port;
    HEX = "true";
  } // extraEnvAttrs;
  envFrom = [{ secretRef.name = secretName; }];
  env = extraEnv;
  securityContext = { privileged = false; };
}
  extraService)
