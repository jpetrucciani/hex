{ pkgs }:
let
  inherit (builtins) listToAttrs readDir;
  inherit (pkgs.lib) hasSuffix mapAttrsToList removeSuffix;
  inherit (pkgs.lib.attrsets) filterAttrs;

  params = { inherit hex pkgs; };
  aws = import ./k8s/aws.nix (params // { inherit services; });
  services = import ./k8s/services.nix params;
  hex = (import ./hex.nix pkgs) // { inherit k8s; };
  helm = (
    fn:
    (listToAttrs (mapAttrsToList fn (filterAttrs (k: v: (v == "directory") || (hasSuffix ".nix" k)) (readDir ./k8s/helm))))
  ) (
    n: _:
      let _fn = import ./k8s/helm/${n}; in {
        name = removeSuffix ".nix" n;
        value = _fn (params // { inherit services; });
      }
  );
  svc =
    (fn: (listToAttrs (mapAttrsToList fn (filterAttrs (k: v: (v == "directory") || (hasSuffix ".nix" k)) (readDir ./k8s/svc)))))
      (
        n: _:
          let _fn = import ./k8s/svc/${n}; in {
            name = removeSuffix ".nix" n;
            value = _fn (params // { inherit services; });
          }
      );
  k8s = helm // {
    inherit aws;
    inherit services svc;
    addons = import ./k8s/addons.nix params;
    cert-manager = import ./k8s/cert-manager.nix params;
    cron = import ./k8s/cron.nix params;
    helm = import ./k8s/helm.nix params;
    nginx-ingress = import ./k8s/nginx-ingress.nix params;
    storage = import ./k8s/storage.nix params;
    tailscale = import ./k8s/tailscale.nix params;
    _ = {
      version = chart_url_fn: v: s: args: chart_url_fn (args // { version = v; sha256 = s; });
      chart = { defaults, chart_url, extraSets ? [ ] }:
        let
          fn =
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
            , kubeVersion ? "1.33"
            , apiVersions ? ""
            , rev ? "" # only used for git charts
            , subPath ? "" # only used for git charts
            }: hex.k8s.helm.build {
              inherit name namespace values valuesAttrs defaultValuesAttrs version sha256 forceNamespace sortYaml preRender postRender kubeVersion apiVersions rev subPath;
              extraFlags = extraFlags ++ [ "--version=${version}" ];
              sets = sets ++ extraSets;
              url = chart_url version;
            };
        in
        { __functor = _: fn; passthru.update = defaults.update or "echo 'no update script set!"; };
    };
  };
in
{
  inherit helm services svc hex params;
}
