# [external-secrets](https://github.com/external-secrets/external-secrets) reads information from a third-party service like AWS Secrets Manager and automatically injects the values as Kubernetes Secrets.
{ hex, ... }:
let
  inherit (hex) attrIf ifNotEmptyAttr toYAMLDoc;

  # NOTE: v0-17-0 and ONWARDS REQUIRES v1 instead of v1beta!
  _apiVersion = beta: if beta then "external-secrets.io/v1beta1" else "external-secrets.io/v1";
  external-secrets = rec {
    defaults = {
      name = "external-secrets";
      namespace = "external-secrets";
      store_name = "gsm";
    };
    values_url = "https://github.com/external-secrets/external-secrets/blob/main/deploy/charts/external-secrets/values.yaml";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./external-secrets.json; };
    chart_url = version: hex.k8s.helm.charts.url.github {
      inherit version;
      org = "external-secrets";
      repo = "external-secrets";
      repoName = "helm-chart";
      chartName = "external-secrets";
    };
    cluster_store = rec {
      build =
        { aws ? false
        , aws_region ? "us-east-1"
        , gcp_project ? null
        , name ? defaults.store_name
        , aws_role ? null
        , secret ? "${name}-creds"
        , filename ? "${name}-creds.json"
        , namespace ? "external-secrets"
        , _beta ? false
        , apiVersion ? _apiVersion _beta
        }: toYAMLDoc (store { inherit name aws aws_region aws_role gcp_project secret filename namespace apiVersion; });
      store =
        { name
        , aws
        , aws_region
        , aws_role
        , gcp_project
        , secret
        , filename
        , namespace
        , apiVersion
        }:
        {
          inherit apiVersion;
          kind = "ClusterSecretStore";
          metadata = {
            inherit name namespace;
            annotations = { } // hex.annotations;
          };
          spec = {
            provider = {
              ${if (gcp_project != null) then "gcpsm" else null} = {
                projectID = gcp_project;
                ${if secret != null then "auth" else null} = {
                  secretRef = {
                    secretAccessKeySecretRef = {
                      inherit namespace;
                      name = secret;
                      key = filename;
                    };
                  };
                };
              };
              ${if aws then "aws" else null} = {
                service = "SecretsManager";
                region = aws_region;
                ${if aws_role != null then "role" else null} = aws_role;
                ${if secret != null then "auth" else null} = {
                  secretRef = {
                    accessKeyIDSecretRef = {
                      inherit namespace;
                      name = secret;
                      key = "access-key";
                    };
                    secretAccessKeySecretRef = {
                      inherit namespace;
                      name = secret;
                      key = "secret-access-key";
                    };
                  };
                };
              };
            };
          };
        };
    };
    external_secret = rec {
      build =
        { name
        , filename
        , env ? ""
        , store ? defaults.store_name
        , store_kind ? "ClusterSecretStore"
        , refresh_interval ? "30m"
        , secret_ref ? ""
        , namespace ? "default"
        , extract ? false
        , decoding_strategy ? "Auto"
        , metadata_policy ? "None"
        , conversion_strategy ? "Default"
        , extra_data ? [ ]
        , labels ? { }
        , string_data ? { }
        , _beta ? false
        , apiVersion ? _apiVersion _beta
        }: toYAMLDoc (secret { inherit name filename env store store_kind refresh_interval secret_ref namespace extract decoding_strategy metadata_policy conversion_strategy extra_data labels string_data _beta apiVersion; });

      secret =
        { name
        , filename
        , env
        , store
        , store_kind
        , refresh_interval
        , secret_ref
        , namespace
        , extract
        , decoding_strategy
        , metadata_policy
        , conversion_strategy
        , extra_data
        , labels
        , string_data
        , _beta
        , apiVersion ? _apiVersion _beta
        }:
        let
          all_labels = labels // { HEX = "true"; };
        in
        {
          inherit apiVersion;
          kind = "ExternalSecret";
          metadata = {
            inherit name namespace;
            annotations = { } // hex.annotations;
          };
          spec = {
            refreshInterval = refresh_interval;
            secretStoreRef = {
              kind = store_kind;
              name = store;
            };
            target = {
              inherit name;
              creationPolicy = "Owner";
              deletionPolicy = "Retain";
              template = {
                ${ifNotEmptyAttr string_data "data"} = string_data;
                metadata = {
                  labels = all_labels;
                };
              };
            };
            ${attrIf extract "dataFrom"} = [
              {
                extract = {
                  key = if secret_ref == "" then "${env}${name}" else secret_ref;
                  conversionStrategy = conversion_strategy;
                  metadataPolicy = metadata_policy;
                  decodingStrategy = decoding_strategy;
                };
              }
            ];
            ${attrIf (!extract) "data"} = [
              {
                secretKey = filename;
                remoteRef = {
                  conversionStrategy = conversion_strategy;
                  decodingStrategy = "None";
                  metadataPolicy = metadata_policy;
                  key = if secret_ref == "" then "${env}${name}" else secret_ref;
                };
              }
            ] ++ extra_data;
          };
        };
    };
  };
in
external-secrets
