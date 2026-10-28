# This hex spell allows concise cron job declaration in Kubernetes.
{ hex, pkgs, services, jobs, ... }:
let
  inherit (hex) concatMapStrings ifNotEmptyAttr toYAMLDoc recursiveUpdate;
  inherit (pkgs.lib.asserts) assertMsg;

  hexEnv = with hex.defaults.env; [
    pod_ip
    pod_name
    { name = "HEX"; value = "true"; }
  ];

  cronJob =
    { context
    , name
    , namespace
    , labels
    , schedule
    , timeZone
    , concurrencyPolicy
    , failedJobsHistoryLimit
    , successfulJobsHistoryLimit
    , jobSpec
    }:
      assert assertMsg (builtins.isAttrs labels)
        "${context}: labels must be an attribute set";
      assert assertMsg (builtins.elem concurrencyPolicy [ "Allow" "Forbid" "Replace" ])
        "${context}: concurrencyPolicy must be Allow, Forbid, or Replace";
      {
        apiVersion = "batch/v1";
        kind = "CronJob";
        metadata = {
          inherit name namespace;
          annotations = { } // hex.annotations;
          ${ifNotEmptyAttr labels "labels"} = labels;
        };
        spec = {
          inherit concurrencyPolicy failedJobsHistoryLimit successfulJobsHistoryLimit schedule timeZone;
          jobTemplate.spec = jobs.components.spec (jobSpec // { inherit context; });
        };
      };

  cron = {
    enum = {
      restart_policy = {
        never = "Never";
        on_failure = "OnFailure";
        always = "Always";
      };
    };
    build =
      { name
      , image ? "curlimages/curl:8.5.0"
      , schedule ? "0 * * * *"  # hourly at :00
      , timeZone ? "UTC"        # UTC - use tz like "America/New_York" for EST
      , labels ? { }
      , namespace ? "default"
      , failedJobsHistoryLimit ? 3
      , successfulJobsHistoryLimit ? 3
      , backoffLimit ? null
      , activeDeadlineSeconds ? null
      , ttlSecondsAfterFinished ? null
      , cpuRequest ? "100m"
      , cpuLimit ? null
      , memoryRequest ? "100Mi"
      , memoryLimit ? null
      , ephemeralStorageRequest ? null
      , ephemeralStorageLimit ? null
      , env ? [ ]
      , envAttrs ? { }
      , envFrom ? [ ]
      , sa ? "default"
      , command ? null
      , args ? null
      , restartPolicy ? "Never"
      , imagePullPolicy ? "Always"
      , imagePullSecrets ? [ ]
      , volumes ? [ ]           # services.volumes entries or the legacy volume format
      , concurrencyPolicy ? "Allow" # Allow, Forbid, Replace
      , securityContext ? { }   # PodSpec securityContext
      , security ? null         # services.security profile
      , extra ? { } # extra escape hatch to use any other options!
      }:
      let
        context = "hex.k8s.cron.build";
        template = services.components.podTemplate {
          inherit context name namespace labels image imagePullPolicy imagePullSecrets volumes security restartPolicy;
          inherit cpuRequest cpuLimit memoryRequest memoryLimit ephemeralStorageRequest ephemeralStorageLimit command args envAttrs envFrom;
          env = hexEnv ++ env;
          serviceAccountName = sa;
          podSecurityContext = securityContext;
          appArmor = null;
        };
      in
      toYAMLDoc (recursiveUpdate
        (cronJob {
          inherit context name namespace labels schedule timeZone concurrencyPolicy failedJobsHistoryLimit successfulJobsHistoryLimit;
          jobSpec = { inherit template backoffLimit activeDeadlineSeconds ttlSecondsAfterFinished; };
        })
        extra);

    kube_cron = {
      build =
        { name
        , image ? "ghcr.io/jpetrucciani/k8s-aws:latest"
        , schedule ? "0 * * * *"  # hourly at :00
        , timeZone ? "UTC"        # UTC - use tz like "America/New_York" for EST
        , labels ? { }
        , namespace ? "default"
        , failedJobsHistoryLimit ? 3
        , successfulJobsHistoryLimit ? 3
        , backoffLimit ? null
        , activeDeadlineSeconds ? null
        , ttlSecondsAfterFinished ? null
        , cpuRequest ? "100m"
        , cpuLimit ? null
        , memoryRequest ? "100Mi"
        , memoryLimit ? null
        , ephemeralStorageRequest ? null
        , ephemeralStorageLimit ? null
        , roleRules ? [
            {
              apiGroups = [ "" ];
              resources = [ "pods" ];
              verbs = [ "delete" "get" "list" ];
            }
          ]
        , env ? [ ]
        , envAttrs ? { }
        , envFrom ? [ ]
        , command ? "bash"
        , args ? [ "-c" ''kubectl get pods'' ]
        , restartPolicy ? "OnFailure"
        , concurrencyPolicy ? "Allow" # Allow, Forbid, Replace
        , extraCron ? { } # extra escape hatch to use any other options!
        , extraCronContainer ? { } # extra escape hatch to use any other options!
        }:
        let
          context = "hex.k8s.cron.kube_cron.build";
          saName = "${name}-sa";
          template = services.components.podTemplate {
            inherit context name namespace labels image restartPolicy;
            inherit cpuRequest cpuLimit memoryRequest memoryLimit ephemeralStorageRequest ephemeralStorageLimit command args envAttrs envFrom;
            env = hexEnv ++ env;
            serviceAccountName = saName;
            imagePullPolicy = null;
            appArmor = null;
          };
          container = recursiveUpdate (builtins.head template.spec.containers) extraCronContainer;
          cron = recursiveUpdate
            (cronJob {
              inherit context name namespace labels schedule timeZone concurrencyPolicy failedJobsHistoryLimit successfulJobsHistoryLimit;
              jobSpec = {
                inherit backoffLimit activeDeadlineSeconds ttlSecondsAfterFinished;
                template = recursiveUpdate template { spec.containers = [ container ]; };
              };
            })
            extraCron;
        in
        ''
          ${concatMapStrings toYAMLDoc (jobs.components.rbac { inherit name namespace saName; rules = roleRules; })}
          ${toYAMLDoc cron}
        '';
    };
  };
in
cron
