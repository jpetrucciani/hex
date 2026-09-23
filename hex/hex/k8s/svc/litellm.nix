{ hex, pkgs, ... }:
let
  litellm =
    { name ? "litellm"
    , version ? "1.102.1"
    , namespace ? "default"
    , image_registry ? "ghcr.io/berriai"
    , image_base ? "litellm-database"
    , image_tag ? version
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
    , initialDelaySeconds ? 10
    , livenessProbe ? {
        httpGet = {
          inherit port;
          path = "/health/liveliness";
        };
        inherit initialDelaySeconds failureThreshold periodSeconds successThreshold timeoutSeconds;
      }
    , readinessProbe ? {
        httpGet = {
          inherit port;
          path = "/health/readiness";
        };
        inherit initialDelaySeconds failureThreshold periodSeconds successThreshold timeoutSeconds;
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
    , valkey ? { }
    }:
    let
      inherit (hex) toYAMLDoc recursiveUpdate;
      bundledValkey = {
        enable = false;
        image = "valkey/valkey:8.1.10-alpine";
        storage = "1Gi";
        storageClass = null;
        cpuRequest = "50m";
        memoryRequest = "128Mi";
        memoryLimit = "512Mi";
        maxmemory = "256mb";
        cacheTtl = 600;
        passwordSecretName = secretName;
        passwordSecretKey = "REDIS_PASSWORD";
      } // valkey;
      valkeyName = "${name}-valkey";
      valkeyLabels = { name = valkeyName; };
      redisHost = valkeyName;
      redisPort = 6379;
      passwordRef = {
        secretKeyRef = {
          name = bundledValkey.passwordSecretName;
          key = bundledValkey.passwordSecretKey;
        };
      };
      effectiveConfig =
        if bundledValkey.enable then
          recursiveUpdate litellm_config
            {
              router_settings = {
                redis_host = "os.environ/REDIS_HOST";
                redis_port = "os.environ/REDIS_PORT";
                redis_password = "os.environ/REDIS_PASSWORD";
              };
              litellm_settings = {
                cache = true;
                cache_params = {
                  type = "redis";
                  host = "os.environ/REDIS_HOST";
                  port = "os.environ/REDIS_PORT";
                  password = "os.environ/REDIS_PASSWORD";
                  ttl = bundledValkey.cacheTtl;
                };
              };
            }
        else litellm_config;

      config = {
        apiVersion = "v1";
        stringData = {
          "config.yaml" = hex.toYAML effectiveConfig;
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
            extraDeploymentAnnotations = extraDeploymentAnnotations // { litellm_config_hash = hex.attrHash effectiveConfig; };
            command = [ "litellm" ];
            args = [ "--config" "/etc/conf/config.yaml" ];
            envAttrs = ({
              HEX = "true";
            } // extraEnvAttrs) // (if bundledValkey.enable then {
              REDIS_HOST = redisHost;
              REDIS_PORT = toString redisPort;
            } else { });
            envFrom = [
              { secretRef.name = secretName; }
            ];
            env = extraEnv ++ (if bundledValkey.enable then [
              { name = "REDIS_PASSWORD"; valueFrom = passwordRef; }
            ] else [ ]);
            securityContext = { privileged = false; };
          }
          extraService);
      valkeyService = {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = valkeyName;
          inherit namespace;
          labels = valkeyLabels;
        };
        spec = {
          clusterIP = "None";
          selector = valkeyLabels;
          ports = [{
            name = "redis";
            port = redisPort;
            targetPort = redisPort;
            protocol = "TCP";
          }];
        };
      };
      valkeyStatefulSet = {
        apiVersion = "apps/v1";
        kind = "StatefulSet";
        metadata = {
          name = valkeyName;
          inherit namespace;
          labels = valkeyLabels;
        };
        spec = {
          replicas = 1;
          serviceName = valkeyName;
          persistentVolumeClaimRetentionPolicy = {
            whenDeleted = "Retain";
            whenScaled = "Retain";
          };
          selector.matchLabels = valkeyLabels;
          template = {
            metadata.labels = valkeyLabels;
            spec = {
              automountServiceAccountToken = false;
              initContainers = [{
                name = "configure-acl";
                inherit (bundledValkey) image;
                command = [ "/bin/sh" "-ec" ];
                args = [
                  ''
                    umask 077
                    test -n "$REDIS_PASSWORD"
                    password_hash="$(printf %s "$REDIS_PASSWORD" | sha256sum | cut -d ' ' -f 1)"
                    printf 'user default on #%s ~* &* +@all\n' "$password_hash" > /run/valkey/users.acl
                    chown valkey:valkey /run/valkey/users.acl
                  ''
                ];
                env = [{ name = "REDIS_PASSWORD"; valueFrom = passwordRef; }];
                securityContext.allowPrivilegeEscalation = false;
                volumeMounts = [{
                  name = "acl";
                  mountPath = "/run/valkey";
                }];
              }];
              containers = [{
                name = "valkey";
                inherit (bundledValkey) image;
                args = [
                  "valkey-server"
                  "--aclfile"
                  "/run/valkey/users.acl"
                  "--appendonly"
                  "yes"
                  "--appendfsync"
                  "everysec"
                  "--maxmemory"
                  bundledValkey.maxmemory
                  "--maxmemory-policy"
                  "noeviction"
                  "--dir"
                  "/data"
                ];
                env = [{ name = "REDISCLI_AUTH"; valueFrom = passwordRef; }];
                securityContext.allowPrivilegeEscalation = false;
                ports = [{ name = "redis"; containerPort = redisPort; }];
                resources = {
                  requests = {
                    cpu = bundledValkey.cpuRequest;
                    memory = bundledValkey.memoryRequest;
                  };
                  limits.memory = bundledValkey.memoryLimit;
                };
                startupProbe = {
                  exec.command = [ "/bin/sh" "-ec" "[ \"$(valkey-cli ping)\" = PONG ]" ];
                  periodSeconds = 5;
                  failureThreshold = 60;
                };
                readinessProbe = {
                  exec.command = [ "/bin/sh" "-ec" "[ \"$(valkey-cli ping)\" = PONG ]" ];
                  periodSeconds = 5;
                };
                livenessProbe = {
                  exec.command = [ "/bin/sh" "-ec" "[ \"$(valkey-cli ping)\" = PONG ]" ];
                  periodSeconds = 10;
                };
                volumeMounts = [
                  { name = "data"; mountPath = "/data"; }
                  { name = "acl"; mountPath = "/run/valkey"; readOnly = true; }
                ];
              }];
              volumes = [{
                name = "acl";
                emptyDir.medium = "Memory";
              }];
            };
          };
          volumeClaimTemplates = [{
            apiVersion = "v1";
            kind = "PersistentVolumeClaim";
            metadata.name = "data";
            spec = {
              accessModes = [ "ReadWriteOnce" ];
              resources.requests.storage = bundledValkey.storage;
              ${if bundledValkey.storageClass != null then "storageClassName" else null} = bundledValkey.storageClass;
            };
          }];
        };
      };
      valkeyNetworkPolicy = {
        apiVersion = "networking.k8s.io/v1";
        kind = "NetworkPolicy";
        metadata = {
          name = "${valkeyName}-policy";
          inherit namespace;
        };
        spec = {
          podSelector.matchLabels = valkeyLabels;
          policyTypes = [ "Ingress" "Egress" ];
          ingress = [{
            from = [{ podSelector.matchLabels = labels; }];
            ports = [{ port = redisPort; protocol = "TCP"; }];
          }];
          egress = [ ];
        };
      };
    in
    ''
      ${toYAMLDoc config}
      ${service}
      ${if bundledValkey.enable then ''
        ${toYAMLDoc valkeyService}
        ${toYAMLDoc valkeyStatefulSet}
        ${toYAMLDoc valkeyNetworkPolicy}
      '' else ""}
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
