# [Authentik](https://github.com/goauthentik/authentik) is an open source IDP written in go
{ hex, ... }:
let
  authentik = rec {
    defaults = {
      name = "authentik";
      namespace = "default";
    };
    values_url = "https://github.com/goauthentik/helm/blob/main/charts/authentik/values.yaml";
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./airflow.json; };
    chart_url = version: "https://github.com/goauthentik/helm/releases/download/authentik-${version}/authentik-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
authentik
