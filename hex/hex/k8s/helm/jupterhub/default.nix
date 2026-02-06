# [jupyterhub](https://github.com/jupyterhub/jupyterhub) is a platform for hosting Jupyter notebooks for many users
{ hex, ... }:
let
  # https://github.com/jupyterhub/zero-to-jupyterhub-k8s/tags
  # https://hub.jupyter.org/helm-chart/
  jupyterhub = rec {
    defaults = {
      name = "jupyterhub";
      namespace = "jupyterhub";
    };
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./jupyterhub.json; };
    chart_url = version: "https://hub.jupyter.org/helm-chart/jupyterhub-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
jupyterhub
