# [external-secrets](https://github.com/external-secrets/external-secrets) reads information from a third-party service like AWS Secrets Manager and automatically injects the values as Kubernetes Secrets.
{ hex, ... }:
let
  inherit (hex) attrIf ifNotEmptyAttr toYAMLDoc;

  external-secrets = rec {
    defaults = {
      name = "external-secrets";
      namespace = "external-secrets";
      store_name = "gsm";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-12-1;
      v0-12-1 = _v "0.12.1" "0vlng3x6ynyhkxa6k9jxfg3fy56iwb6mbca6v2lqjka2d55p7a0g"; # 2024-12-23
      v0-11-0 = _v "0.11.0" "09j65l2h0g7cdlp1iif18y8c51vndkm1pkjw1kxrx26g82373lbn"; # 2024-12-02
      v0-10-7 = _v "0.10.7" "0wv50rsdgp2sghkgkwr2ryzbvfbcnmx0ccgm3vvflkm2yy062v8y"; # 2024-11-23
      v0-10-6 = _v "0.10.6" "1qk8y5kml3dp394j59ffai5b3npbby1410sgf20smdslq3fx4a8i"; # 2024-11-20
      v0-10-5 = _v "0.10.5" "1873pfq6l6xjp2kb7x10fzcj0iljfdvgnbv0dml2s7vcmsa9y5i9"; # 2024-10-25
      v0-10-4 = _v "0.10.4" "09r20z96b8rzh6hnl172775na3wgrcn17x2kblagmgrwbzdidwvd"; # 2024-09-25
      v0-9-20 = _v "0.9.20" "1i08zphbasfk4nkfr0fc0hixbqqpd3x4a1chxcl88xbgs7gjl3xy"; # 2024-07-06
      v0-9-19 = _v "0.9.19" "11j5n878b0b2ncn3fd1nilpl6s0ir6lxz9v14hn0dnplybkbr1qg"; # 2024-06-04
      v0-9-18 = _v "0.9.18" "0jiva7qgnsb4d1711xffh9ccbs78qjdhw98iq33sg3lmyqk3hjsh"; # 2024-05-14
      v0-9-17 = _v "0.9.17" "0scsqcc5sfqd5yhyhi1c78clcs7szs1gfas7al05qjnjbb3hvbis"; # 2024-05-01
      v0-9-16 = _v "0.9.16" "1lib2rf12iw4spk6qkp8wsxm35hvfxnb4i0awkf12ds3ddxs84cr"; # 2024-04-18
      v0-9-14 = _v "0.9.14" "0r0g9bv30qywlw1qlk4i581pvsmrmc5bxp7nxbm1lmqq6a6ihv16"; # 2024-03-30
      v0-9-13 = _v "0.9.13" "00mmhqy70n9q512zgf15kpcn22ri9vzx9bx782j3pz59ppa849i4"; # 2024-02-17
      v0-9-12 = _v "0.9.12" "1pvg8qxsih5yvn3g5k1ampr80vcc131vspmx4diw9m19bwnrcvhw"; # 2024-02-09
      v0-9-11 = _v "0.9.11" "1aij5xw944gc18whmfqh9qz483c5xlyvv3bl0r7j1i234vkl7zkj"; # 2023-12-25
      v0-8-7 = _v "0.8.7" "0q8pzcxix151b3jsiszz1la6fl98nkwxi7bimhm2zyy0ws532lc0";
      v0-7-2 = _v "0.7.2" "17isdcbb94kqwxg0v0mfj1ypjiqn3airghnd1bswlg609w73a8h4";
      v0-6-1 = _v "0.6.1" "02kacs4wdp5q9dlpndkzj4fxi30kpl6gxfqalgq5q9y3vr3l5gwv";
      v0-5-9 = _v "0.5.9" "0mxm237a7q8gvxvpcqk6zs0rbv725260xdvhd27kibirfjwm4zxl";
    };
    chart_url = version: hex.k8s.helm.charts.url.github {
      inherit version;
      org = "external-secrets";
      repo = "external-secrets";
      repoName = "helm-chart";
      chartName = "external-secrets";
    };
    chart = hex.k8s._.chart { inherit defaults chart_url; };
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
        }: toYAMLDoc (store { inherit name aws aws_region aws_role gcp_project secret filename namespace; });
      store =
        { name
        , aws
        , aws_region
        , aws_role
        , gcp_project
        , secret
        , filename
        , namespace
        }:
        {
          apiVersion = "external-secrets.io/v1beta1";
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
        }: toYAMLDoc (secret { inherit name filename env store store_kind refresh_interval secret_ref namespace extract decoding_strategy metadata_policy conversion_strategy extra_data labels string_data; });

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
        }:
        let
          all_labels = labels // { HEX = "true"; };
        in
        {
          apiVersion = "external-secrets.io/v1beta1";
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