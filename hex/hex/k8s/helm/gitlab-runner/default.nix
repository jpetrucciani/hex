# This module contains the helm chart for the [GitLab Kubernetes Executor](https://docs.gitlab.com/runner/executors/kubernetes.html).
{ hex, ... }:
let
  gitlab-runner = rec {
    docs_meta = {
      source = "https://gitlab.com/gitlab-org/gitlab-runner";
    };
    defaults = {
      name = "gitlab-runner";
      namespace = "gitlab";
    };
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./gitlab-runner.json; };
    chart_url = version: "https://gitlab-charts.s3.amazonaws.com/gitlab-runner-${version}.tgz";
    values_url = "https://gitlab.com/gitlab-org/charts/gitlab-runner/blob/main/values.yaml";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
gitlab-runner
