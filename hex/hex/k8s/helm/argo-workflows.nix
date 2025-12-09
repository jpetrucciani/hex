# [argo-workflows](https://github.com/argoproj/argo-workflows) is a workflow engine for kubernetes
{ hex, ... }:
let
  # values here: https://github.com/argoproj/argo-helm/blob/main/charts/argo-workflows/values.yaml
  name = "argo-workflows";
  argo-workflows = rec {
    defaults = {
      inherit name;
      namespace = "default";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-46-1;
      v0-46-1 = _v "0.46.1" "0j7qbzvflm62m9wpcp8jjb86n200fg33cvc94jigmxclvbq45361"; # 2025-12-02
    };
    chart_url = version: "https://github.com/argoproj/argo-helm/releases/download/argo-workflows-${version}/argo-workflows-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
argo-workflows
