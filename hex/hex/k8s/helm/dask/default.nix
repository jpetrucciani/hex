# [dask](https://docs.dask.org/en/stable/) is a python library/framework for parallel and distributed computing 
{ hex, ... }:
let
  namespace = "dask";
  kubernetes-operator =
    let
      # https://docs.dask.org/en/stable/deploying-kubernetes.html
      name = "dask-operator";
    in
    rec {
      __functor = _: version.latest;
      defaults = {
        inherit name namespace;
      };
      version = hex.k8s._.versionMap { inherit chart; versionFile = ./kubernetes-operator.json; };
      chart_url = version: "https://helm.dask.org/dask-kubernetes-operator-${version}.tgz";
      values_url = "https://github.com/dask/dask-kubernetes/blob/main/dask_kubernetes/operator/deployment/helm/dask-kubernetes-operator/values.yaml";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
in
{
  inherit kubernetes-operator;
}
