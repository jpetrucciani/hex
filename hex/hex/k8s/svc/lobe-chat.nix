{ hex, pkgs, ... }:
let
  inherit (pkgs.lib) recursiveUpdate;
  volumes = [ hex.k8s.services.components.volumes.tmp ];
  lobechat =
    { name ? "lobe-chat"
    , namespace ? "default"
    , image_base ? "lobehub/lobe-chat${if database then "-database" else ""}"
    , image_tag ? "1.88.6"
    , image ? "${image_base}:${image_tag}"
    , database ? false
    , replicas ? 1
    , cpuRequest ? "0.2"
    , cpuLimit ? "1"
    , memoryRequest ? "1Gi"
    , memoryLimit ? "4Gi"
    , autoscale ? false
    , extraEnv ? [ ]
    , extraEnvAttrs ? { }
    , port ? 3210
    , secretName ? "lobe-chat-secret"
    , readinessProbe ? null
    , maxUnavailable ? 0
    , maxSurge ? "50%"
    , labels ? {
        inherit name;
        tier = "app";
      }
    , extraService ? { } # escape hatch to inject other service spec
    , extraDeploymentAnnotations ? { }
    }: hex.k8s.services.build (recursiveUpdate
      {
        inherit name namespace labels port image replicas cpuRequest cpuLimit memoryRequest memoryLimit autoscale volumes readinessProbe maxUnavailable maxSurge extraDeploymentAnnotations;
        envAttrs = {
          PORT = toString port;
          HEX = "true";
        } // extraEnvAttrs;
        envFrom = [{ secretRef.name = secretName; }];
        env = extraEnv;
        securityContext = { privileged = false; };
      }
      extraService);
in
{
  __functor = _: lobechat;
  updater =
    let
      inherit (hex.updater.utils) dockerhub_latest_tag;
    in
    pkgs.writers.writeBashBin "update" ''${dockerhub_latest_tag} lobehub lobe-chat'';
}
