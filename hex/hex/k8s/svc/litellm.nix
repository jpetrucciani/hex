{ hex, pkgs, ... }:
let
  litellm =
    { name ? "litellm"
    , version ? "v1.80.8"
    , namespace ? "default"
    , image_registry ? "ghcr.io/berriai"
    , image_base ? "litellm-database"
    , image_tag ? "litellm_stable_release_branch-${version}-stable"
    , image ? "${image_registry}/${image_base}:${image_tag}"
    , replicas ? 1
    , cpuRequest ? "0.5"
    , cpuLimit ? "2"
    , memoryRequest ? "1Gi"
    , memoryLimit ? "4Gi"
    , autoscale ? false
    , extraEnv ? [ ]
    , extraEnvAttrs ? { }
    , extraVolumes ? [ ]
    , port ? 4000
    , secretName ? "litellm-secret"
    , failureThreshold ? 3
    , periodSeconds ? 10
    , successThreshold ? 1
    , timeoutSeconds ? 4
    , livenessProbe ? {
        httpGet = {
          inherit port;
          path = "/health/liveliness";
        };
        inherit failureThreshold periodSeconds successThreshold timeoutSeconds;
      }
    , readinessProbe ? {
        httpGet = {
          inherit port;
          path = "/health/readiness";
        };
        inherit failureThreshold periodSeconds successThreshold timeoutSeconds;
      }
    , maxUnavailable ? 0
    , maxSurge ? "50%"
    , litellm_config ? {
        model_list = [
          {
            litellm_params = {
              model = "groq/openai/gpt-oss-120b";
              drop_params = true;
            };
            model_name = "gpt-oss-120b";
          }
        ];
      }
    , litellm-conf ? "${name}-litellm-conf"
    , labels ? {
        inherit name;
        tier = "api";
      }
    , extraService ? { } # escape hatch to inject other service spec
    , extraDeploymentAnnotations ? { }
    }:
    let
      inherit (hex) toYAMLDoc recursiveUpdate;

      config = {
        apiVersion = "v1";
        stringData = {
          "config.yaml" = hex.toYAML litellm_config;
        };
        kind = "Secret";
        metadata = {
          inherit namespace;
          labels = {
            HEX = "true";
          };
          name = litellm-conf;
        };
        type = "Opaque";
      };

      volumes = [
        {
          name = "litellm-conf";
          secret = litellm-conf;
          mountPath = "/etc/conf";
        }
        hex.k8s.services.components.volumes.tmp
      ] ++ extraVolumes;
      service = hex.k8s.services.build
        (recursiveUpdate
          {
            inherit name namespace labels port image replicas cpuRequest cpuLimit memoryRequest memoryLimit autoscale volumes livenessProbe readinessProbe maxUnavailable maxSurge;
            extraDeploymentAnnotations = extraDeploymentAnnotations // { litellm_config_hash = hex.attrHash litellm_config; };
            command = [ "litellm" ];
            args = [ "--config" "/etc/conf/config.yaml" ];
            envAttrs = {
              HEX = "true";
            } // extraEnvAttrs;
            envFrom = [
              { secretRef.name = secretName; }
            ];
            env = extraEnv;
            securityContext = { privileged = false; };
          }
          extraService);
    in
    ''
      ${toYAMLDoc config}
      ${service}
    '';
in
{
  __functor = _: litellm;
  updater =
    let
      inherit (hex.updater.utils) github_latest_tag;
    in
    pkgs.writers.writeBashBin "update" ''${github_latest_tag} berriai litellm'';
}
