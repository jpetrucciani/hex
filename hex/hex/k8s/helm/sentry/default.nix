# [sentry](https://github.com/getsentry/sentry) is a Developer-first error tracking and performance monitoring platform.
{ hex, ... }:
let
  sentry = rec {
    defaults = {
      name = "sentry";
      namespace = "sentry";
    };
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./sentry.json; };
    chart = hex.k8s._.chart { inherit defaults chart_url; };
    chart_url = version: "https://sentry-kubernetes.github.io/charts/sentry-${version}.tgz";
    values_url = "https://github.com/sentry-kubernetes/charts/blob/develop/charts/sentry/values.yaml";
  };
in
sentry
