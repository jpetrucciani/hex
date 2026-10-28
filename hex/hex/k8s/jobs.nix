# This module allows concise one-off Job declaration in Kubernetes: migrations, backfills, debug shells, and more.
{ hex, pkgs, services, ... }:
let
  inherit (hex) attrHash concatMapStrings concatStringsSep ifNotNull toYAMLDoc;
  inherit (builtins) all attrNames elem isAttrs isBool isInt isList isString stringLength substring;
  inherit (pkgs.lib.asserts) assertMsg;

  isNullOrPositiveInt = value: value == null || (isInt value && value > 0);
  isNullOrNonNegativeInt = value: value == null || (isInt value && value >= 0);

  hookAnnotations = {
    argo-presync = {
      "argocd.argoproj.io/hook" = "PreSync";
      "argocd.argoproj.io/hook-delete-policy" = "BeforeHookCreation";
    };
    argo-sync = {
      "argocd.argoproj.io/hook" = "Sync";
      "argocd.argoproj.io/hook-delete-policy" = "BeforeHookCreation";
    };
    argo-postsync = {
      "argocd.argoproj.io/hook" = "PostSync";
      "argocd.argoproj.io/hook-delete-policy" = "BeforeHookCreation";
    };
    helm-pre-upgrade = {
      "helm.sh/hook" = "pre-install,pre-upgrade";
      "helm.sh/hook-delete-policy" = "before-hook-creation";
    };
    helm-post-upgrade = {
      "helm.sh/hook" = "post-install,post-upgrade";
      "helm.sh/hook-delete-policy" = "before-hook-creation";
    };
  };

  # the PodSpec fields a Job copies from its service; everything else uses Job defaults
  inheritedServiceFields = [
    "appArmor"
    "env"
    "envAttrs"
    "envFrom"
    "hostAliases"
    "image"
    "imagePullSecrets"
    "namespace"
    "nodeSelector"
    "podSecurityContext"
    "pre1_30"
    "security"
    "securityContext"
    "tolerations"
    "volumes"
  ];

  jobs = rec {
    hooks = attrNames hookAnnotations;

    components = {
      # batch/v1 JobSpec shared by Jobs and CronJobs; null fields are omitted
      spec =
        { context
        , template
        , backoffLimit ? null
        , activeDeadlineSeconds ? null
        , ttlSecondsAfterFinished ? null
        , parallelism ? null
        , completions ? null
        , completionMode ? null
        , podFailurePolicy ? null
        }:
        let
          restartPolicy = template.spec.restartPolicy or null;
        in
        assert assertMsg (isNullOrNonNegativeInt backoffLimit)
          "${context}: backoffLimit must be null or a non-negative integer";
        assert assertMsg (isNullOrPositiveInt activeDeadlineSeconds)
          "${context}: activeDeadlineSeconds must be null or a positive integer";
        assert assertMsg (isNullOrNonNegativeInt ttlSecondsAfterFinished)
          "${context}: ttlSecondsAfterFinished must be null or a non-negative integer";
        assert assertMsg (isNullOrNonNegativeInt parallelism)
          "${context}: parallelism must be null or a non-negative integer";
        assert assertMsg (isNullOrPositiveInt completions)
          "${context}: completions must be null or a positive integer";
        assert assertMsg (completionMode == null || elem completionMode [ "Indexed" "NonIndexed" ])
          "${context}: completionMode must be null, Indexed, or NonIndexed";
        assert assertMsg (completionMode != "Indexed" || completions != null)
          "${context}: Indexed completionMode requires completions";
        assert assertMsg (elem restartPolicy [ "Never" "OnFailure" ])
          "${context}: restartPolicy must be Never or OnFailure";
        assert assertMsg (podFailurePolicy == null || (isAttrs podFailurePolicy && podFailurePolicy ? rules && isList podFailurePolicy.rules))
          "${context}: podFailurePolicy must be null or an attribute set with a rules list";
        assert assertMsg (podFailurePolicy == null || restartPolicy == "Never")
          "${context}: podFailurePolicy requires restartPolicy = Never";
        {
          inherit template;
          ${ifNotNull backoffLimit "backoffLimit"} = backoffLimit;
          ${ifNotNull activeDeadlineSeconds "activeDeadlineSeconds"} = activeDeadlineSeconds;
          ${ifNotNull ttlSecondsAfterFinished "ttlSecondsAfterFinished"} = ttlSecondsAfterFinished;
          ${ifNotNull parallelism "parallelism"} = parallelism;
          ${ifNotNull completions "completions"} = completions;
          ${ifNotNull completionMode "completionMode"} = completionMode;
          ${ifNotNull podFailurePolicy "podFailurePolicy"} = podFailurePolicy;
        };

      # ServiceAccount plus an optional namespaced Role and RoleBinding
      rbac =
        { name
        , namespace
        , saName
        , rules ? [ ]
        , imagePullSecrets ? [ ]
        }:
        [
          (services.components.service-account {
            inherit namespace imagePullSecrets;
            name = saName;
            saSuffix = "";
          })
        ]
        ++ (if rules == [ ] then [ ] else [
          (services.components.role {
            inherit namespace rules;
            name = "${name}-role";
          })
          {
            apiVersion = "rbac.authorization.k8s.io/v1";
            kind = "RoleBinding";
            metadata = {
              inherit namespace;
              name = "${name}-rb";
            };
            roleRef = {
              apiGroup = "rbac.authorization.k8s.io";
              kind = "Role";
              name = "${name}-role";
            };
            subjects = [{
              kind = "ServiceAccount";
              name = saName;
            }];
          }
        ]);
    };

    # remaining args (resources, env, volumes, sidecars, security, ...) match services.build
    build =
      { name
      , image
      , namespace ? "default"
      , labels ? { app = name; }       # keep these distinct from service labels so Services never select Job pods
      , restartPolicy ? "Never"
      , backoffLimit ? 3
      , activeDeadlineSeconds ? null
      , ttlSecondsAfterFinished ? null # with plain apply or GitOps, a deleted Job is recreated and reruns
      , parallelism ? null
      , completions ? null
      , completionMode ? null
      , podFailurePolicy ? null
      , hook ? null                    # one of jobs.hooks; runs the Job as an Argo CD or Helm hook
      , hashName ? hook == null        # suffix the name with a spec hash, since Job templates are immutable
      , serviceAccount ? true
      , serviceAccountName ? null      # use an existing ServiceAccount instead of creating one
      , saSuffix ? "-sa"
      , roleRules ? [ ]
      , cpuRequest ? "100m"
      , memoryRequest ? "256Mi"
      , extraJobAnnotations ? { }
      , extraJob ? { }
      , ...
      }@args:
      let
        context = "hex.k8s.jobs.build";
        saName =
          if serviceAccountName != null then serviceAccountName
          else if serviceAccount then "${name}${saSuffix}"
          else "default";
        createServiceAccount = serviceAccountName == null && serviceAccount;
        template = services.components.podTemplate (builtins.removeAttrs args [
          "activeDeadlineSeconds"
          "backoffLimit"
          "completionMode"
          "completions"
          "extraJob"
          "extraJobAnnotations"
          "hashName"
          "hook"
          "parallelism"
          "podFailurePolicy"
          "roleRules"
          "saSuffix"
          "serviceAccount"
          "serviceAccountName"
          "ttlSecondsAfterFinished"
        ] // {
          inherit context labels image cpuRequest memoryRequest restartPolicy;
          serviceAccountName = saName;
        });
        spec = components.spec {
          inherit context template backoffLimit activeDeadlineSeconds ttlSecondsAfterFinished parallelism completions completionMode podFailurePolicy;
        };
        jobName = if hashName then "${name}-${substring 0 8 (attrHash spec)}" else name;
        job = {
          apiVersion = "batch/v1";
          kind = "Job";
          metadata = {
            inherit namespace labels;
            name = jobName;
            annotations = (if hook == null then { } else hookAnnotations.${hook}) // extraJobAnnotations // hex.annotations;
          };
          inherit spec;
        } // extraJob;
        rbac = components.rbac {
          inherit name namespace saName;
          rules = roleRules;
          imagePullSecrets = args.imagePullSecrets or [ ];
        };
      in
      assert assertMsg (isString name && name != "")
        "${context}: name must be a non-empty string";
      assert assertMsg (isAttrs labels && labels != { })
        "${context}: labels must be a non-empty attribute set";
      assert assertMsg (hook == null || elem hook hooks)
        "${context}: hook must be null or one of ${concatStringsSep ", " hooks}";
      assert assertMsg (isBool hashName)
        "${context}: hashName must be a boolean";
      assert assertMsg (stringLength jobName <= 63)
        "${context}: Job name ${jobName} must be at most 63 characters";
      assert assertMsg (isList roleRules && all isAttrs roleRules)
        "${context}: roleRules must be a list of PolicyRule attribute sets";
      assert assertMsg (roleRules == [ ] || createServiceAccount)
        "${context}: roleRules require a ServiceAccount created by this Job";
      ''
        ${if createServiceAccount then concatMapStrings toYAMLDoc rbac else ""}
        ${toYAMLDoc job}
      '';

    # a Job that runs with a service's image, config, and ServiceAccount; `service` is the services.build argument set
    fromService = service: job:
      let
        context = "hex.k8s.jobs.fromService";
        inherited = pkgs.lib.filterAttrs (field: _: elem field inheritedServiceFields) service;
        saSuffix = service.saSuffix or (services.defaultSaSuffix (service.suffix or ""));
        configHash = services.configs.hash (service.configs or [ ]);
      in
      assert assertMsg (isAttrs service && service ? name && service ? image)
        "${context}: service must be a services.build argument set with name and image";
      assert assertMsg (isAttrs job && job ? name)
        "${context}: job must be an attribute set with a name";
      build (inherited // { serviceAccountName = "${service.name}${saSuffix}"; } // job // {
        extraPodAnnotations = {
          ${ifNotNull configHash "checksum/config"} = configHash;
        } // (job.extraPodAnnotations or { });
      });

    # an idle pod with a service's image and config for `kubectl exec`; it stops after activeDeadlineSeconds
    shell = service: job:
      fromService service ({
        name = "${service.name}-shell";
        command = [ "tail" ];
        args = [ "-f" "/dev/null" ];
        hashName = false;
        backoffLimit = 0;
        activeDeadlineSeconds = 14400;
        ttlSecondsAfterFinished = 300;
      } // job);
  };
in
jobs
