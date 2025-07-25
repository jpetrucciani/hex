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
      latest = v0-18-2;
      v0-18-2 = _v "0.18.2" "1r783i6i2bphnn2mycsw3qmcm02j0sb3a9gnq331zdl65bzj7c0z"; # 2025-07-03
      v0-18-1 = _v "0.18.1" "08dcppzgsnwyca72s9sp4zkkvs0wsa6zm97m8ydxdfpy3llmjzk1"; # 2025-06-26
      v0-18-0 = _v "0.18.0" "08gl4iyxnds9xfdapgr5101n5irjvg4ynkxs1prnn621yxnb9hdl"; # 2025-06-17
      v0-17-0 = _v "0.17.0" "0bcn9iwd6i7jfsmcjwly5i3h3wlbcdbnk4b8phm1dvsg545kph1q"; # 2025-05-15  # THIS RELEASE ONWARDS REQUIRES v1 instead of v1beta!
      v0-16-2 = _v "0.16.2" "0h4gbwg9yk9r7xrrn5zsh3478yc241idqa12m939hnmkc1pni95a"; # 2025-05-07
      v0-16-1 = _v "0.16.1" "0dpv9529caksc0mpjmd0gqpfhvzgka9a9d04nw647qhpvxqn6ajc"; # 2025-04-16
      v0-16-0 = _v "0.16.0" "1wbr0v0wi0sfiyxsbzcwwjn9c5j0vs4z1w12glwf22101q1ci8z5"; # 2025-04-14
      v0-15-1 = _v "0.15.1" "0h2w9byijx4k91f2aznzilcd846q94sknx4ss3l4cv7vnn4xrg4q"; # 2025-03-28
      v0-15-0 = _v "0.15.0" "16pymmyh8gpi704wzyd600kp7722wbxh3r4fss034ya4lxkgv6lb"; # 2025-03-19
      v0-14-4 = _v "0.14.4" "1v3mk38n92sza0k1smm8fbn35f786xf27h731jfzgpgkmycwamjy"; # 2025-03-10
      v0-14-3 = _v "0.14.3" "0i23y7fgbw06d0q5pcizlgfwbs7dhxdf1afc2m0ihjfn2j563avy"; # 2025-02-26
      v0-14-2 = _v "0.14.2" "0dyib0qrb7cxq42qkwi6mp72vi329xrp3ip9bh4vaalj0ks3fm5g"; # 2025-02-13
      v0-14-1 = _v "0.14.1" "1vfbwlvpv6ckycsf8iyvdhkz1m4bazbpb47fp3qkxsaa1vi88lg7"; # 2025-02-08
      v0-14-0 = _v "0.14.0" "1xq6w4h0g2ibq4aaywqv843bzr0p5yr7ml4a3n264cmydqij77kp"; # 2025-02-04
      v0-13-0 = _v "0.13.0" "1ly3iqvs2yxipjb3zq47id78nwyggzkpszq6w8h64lm1mash6ih9"; # 2025-01-21
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
        , _beta ? false
        , apiVersion ? if _beta then "external-secrets.io/v1beta1" else "external-secrets.io/v1"
        }: toYAMLDoc (store { inherit name aws aws_region aws_role gcp_project secret filename namespace _beta apiVersion; });
      store =
        { name
        , aws
        , aws_region
        , aws_role
        , gcp_project
        , secret
        , filename
        , namespace
        , _beta
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
        , apiVersion ? if _beta then "external-secrets.io/v1beta1" else "external-secrets.io/v1"
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
        , apiVersion
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
