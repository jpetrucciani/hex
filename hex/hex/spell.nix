# this is the nix function that is actually run when you run the `hex` command
nixpkgs: SPELL:
let
  inherit (builtins) functionArgs isFunction intersectAttrs;
  inherit (builtins) listToAttrs pathExists readDir;
  inherit (pkgs.lib) hasSuffix mapAttrsToList optionalAttrs removeSuffix;
  inherit (pkgs.lib.attrsets) filterAttrs;
  pkgs = import nixpkgs { };
  k8s = rec {
    addons = import ./k8s/addons.nix params;
    airbyte = import ./k8s/airbyte.nix params;
    argocd = import ./k8s/argocd.nix params;
    authentik = import ./k8s/authentik.nix params;
    aws = import ./k8s/aws.nix (params // { inherit services; });
    cert-manager = import ./k8s/cert-manager.nix params;
    cron = import ./k8s/cron.nix params;
    custom-pod-autoscaler = import ./k8s/custom-pod-autoscaler.nix params;
    dask = import ./k8s/dask.nix params;
    datadog = import ./k8s/datadog.nix params;
    elastic = import ./k8s/elastic.nix params;
    external-secrets = import ./k8s/external-secrets.nix params;
    fission = import ./k8s/fission.nix params;
    fleet = import ./k8s/fleet.nix params;
    flipt = import ./k8s/flipt.nix params;
    gateway-api = import ./k8s/gateway-api.nix params;
    gitlab-runner = import ./k8s/gitlab-runner.nix params;
    grafana = import ./k8s/grafana.nix params;
    helm = import ./k8s/helm.nix params;
    infisical = import ./k8s/infisical.nix params;
    jupyterhub = import ./k8s/jupyterhub.nix params;
    kong = import ./k8s/kong.nix params;
    langflow = import ./k8s/langflow.nix params;
    mongo = import ./k8s/mongo.nix params;
    nginx-ingress = import ./k8s/nginx-ingress.nix params;
    oneuptime = import ./k8s/oneuptime.nix params;
    open-webui = import ./k8s/open-webui.nix params;
    otf = import ./k8s/otf.nix params;
    plane = import ./k8s/plane.nix params;
    postgres = import ./k8s/postgres.nix params;
    prometheus = import ./k8s/prometheus.nix params;
    pulp = import ./k8s/pulp.nix params;
    quickwit = import ./k8s/quickwit.nix params;
    rancher = import ./k8s/rancher.nix params;
    redis = import ./k8s/redis.nix params;
    robusta = import ./k8s/robusta.nix params;
    searxng = import ./k8s/searxng.nix params;
    sentry = import ./k8s/sentry.nix params;
    services = import ./k8s/services.nix params;
    signoz = import ./k8s/signoz.nix params;
    sonarqube = import ./k8s/sonarqube.nix params;
    stackstorm = import ./k8s/stackstorm.nix params;
    storage = import ./k8s/storage.nix params;
    tailscale = import ./k8s/tailscale.nix params;
    tofutf = import ./k8s/tofutf.nix params;
    traefik = import ./k8s/traefik.nix params;
    svc =
      (
        fn:
        optionalAttrs (pathExists ./k8s/svc)
          (listToAttrs (mapAttrsToList fn (filterAttrs (k: v: (v == "directory") || (hasSuffix ".nix" k)) (readDir ./k8s/svc))))
      ) (
        n: _:
          let _fn = import ./k8s/svc/${n}; in {
            name = removeSuffix ".nix" n;
            value = _fn { inherit hex pkgs services; };
          }
      );
    _ = {
      version = chart_url_fn: v: s: args: chart_url_fn (args // { version = v; sha256 = s; });
      chart = { defaults, chart_url, extraSets ? [ ] }:
        { name ? defaults.name or ""
        , namespace ? defaults.namespace or "default"
        , values ? [ ]
        , valuesAttrs ? null
        , defaultValuesAttrs ? defaults.valuesAttrs or null
        , sets ? [ ]
        , version ? defaults.version or ""
        , sha256 ? defaults.sha256 or ""
        , forceNamespace ? true
        , extraFlags ? [ ]
        , sortYaml ? false
        , preRender ? defaults.preRender or ""
        , postRender ? defaults.postRender or ""
        , kubeVersion ? "1.30"
        , apiVersions ? ""
        }: hex.k8s.helm.build {
          inherit name namespace values valuesAttrs defaultValuesAttrs version sha256 forceNamespace sortYaml preRender postRender kubeVersion apiVersions;
          extraFlags = extraFlags ++ [ "--version=${version}" ];
          sets = sets ++ extraSets;
          url = chart_url version;
        };
    };
  };
  hex = (import ./hex.nix pkgs) // { inherit k8s; };
  params = { inherit hex pkgs; };
  spell = import SPELL;
  output = if isFunction spell then spell (intersectAttrs (functionArgs spell) params) else spell;
in
output
