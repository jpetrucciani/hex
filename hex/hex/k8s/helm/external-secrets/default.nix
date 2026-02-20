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
      # docs: render a ClusterSecretStore manifest with AWS or GCP provider auth wiring.
      build =
        { aws ? false  # type: bool; enable AWS Secrets Manager provider
        , aws_region ? "us-east-1"  # type: string; AWS region for Secrets Manager
        , gcp_project ? null  # type: string | null; GCP project ID for gcpsm provider
        , name ? defaults.store_name  # type: string; ClusterSecretStore resource name
        , aws_role ? null  # type: string | null; optional IAM role ARN for AWS auth
        , secret ? "${name}-creds"  # type: string | null; credential secret name, set null to disable secretRef auth
        , filename ? "${name}-creds.json"  # type: string; key in credential secret for GCP JSON credentials
        , namespace ? "external-secrets"  # type: string; namespace containing credential secret
        , _beta ? false  # type: bool; force v1beta1 API when needed
        , apiVersion ? _apiVersion _beta  # type: string; override external-secrets API version
        }: toYAMLDoc (store { inherit name aws aws_region aws_role gcp_project secret filename namespace apiVersion; });
      # docs: build a raw ClusterSecretStore attrset for advanced composition.
      store =
        { name  # type: string; ClusterSecretStore resource name
        , aws  # type: bool; enable AWS Secrets Manager provider
        , aws_region  # type: string; AWS region for Secrets Manager
        , aws_role  # type: string | null; optional IAM role ARN for AWS auth
        , gcp_project  # type: string | null; GCP project ID for gcpsm provider
        , secret  # type: string | null; credential secret name, set null to disable secretRef auth
        , filename  # type: string; key in credential secret for GCP JSON credentials
        , namespace  # type: string; namespace containing credential secret
        , apiVersion  # type: string; external-secrets API version
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
      # docs: render an ExternalSecret manifest with defaults for target/template behavior.
      build =
        { name  # type: string; target Kubernetes Secret name
        , filename  # type: string; secret key written in target Kubernetes Secret
        , env ? ""  # type: string; optional prefix added to remote secret key lookup
        , store ? defaults.store_name  # type: string; SecretStore or ClusterSecretStore name
        , store_kind ? "ClusterSecretStore"  # type: string; SecretStore reference kind
        , refresh_interval ? "30m"  # type: string; refresh interval for reconciliation
        , secret_ref ? ""  # type: string; explicit remote secret key override
        , namespace ? "default"  # type: string; namespace for ExternalSecret resource
        , extract ? false  # type: bool; use dataFrom.extract mode instead of data list
        , decoding_strategy ? "Auto"  # type: string; decodingStrategy passed to external-secrets
        , metadata_policy ? "None"  # type: string; metadataPolicy passed to external-secrets
        , conversion_strategy ? "Default"  # type: string; conversionStrategy passed to external-secrets
        , extra_data ? [ ]  # type: list; extra entries appended to spec.data
        , labels ? { }  # type: attrset; extra labels merged into target secret template metadata
        , string_data ? { }  # type: attrset; template string data rendered into target secret
        , engineVersion ? "v2"  # type: string; external-secrets template engine version
        , mergePolicy ? if string_data == { } then "Replace" else "Merge"  # type: string; template merge policy
        , _beta ? false  # type: bool; force v1beta1 API when needed
        , apiVersion ? _apiVersion _beta  # type: string; override external-secrets API version
        }: toYAMLDoc (secret { inherit name filename env store store_kind refresh_interval secret_ref namespace extract decoding_strategy metadata_policy conversion_strategy extra_data labels string_data engineVersion mergePolicy _beta apiVersion; });

      # docs: build a raw ExternalSecret attrset for advanced composition.
      secret =
        { name  # type: string; target Kubernetes Secret name
        , filename  # type: string; secret key written in target Kubernetes Secret
        , env  # type: string; optional prefix added to remote secret key lookup
        , store  # type: string; SecretStore or ClusterSecretStore name
        , store_kind  # type: string; SecretStore reference kind
        , refresh_interval  # type: string; refresh interval for reconciliation
        , secret_ref  # type: string; explicit remote secret key override
        , namespace  # type: string; namespace for ExternalSecret resource
        , extract  # type: bool; use dataFrom.extract mode instead of data list
        , decoding_strategy  # type: string; decodingStrategy passed to external-secrets
        , metadata_policy  # type: string; metadataPolicy passed to external-secrets
        , conversion_strategy  # type: string; conversionStrategy passed to external-secrets
        , extra_data  # type: list; extra entries appended to spec.data
        , labels  # type: attrset; extra labels merged into target secret template metadata
        , string_data  # type: attrset; template string data rendered into target secret
        , engineVersion  # type: string; external-secrets template engine version
        , mergePolicy  # type: string; template merge policy
        , _beta  # type: bool; force v1beta1 API when needed
        , apiVersion ? _apiVersion _beta  # type: string; override external-secrets API version
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
                inherit engineVersion mergePolicy;
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
