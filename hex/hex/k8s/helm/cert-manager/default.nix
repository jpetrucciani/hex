# [cert-manager](https://github.com/cert-manager/cert-manager) is a way to automatically provision and manage TLS certificates in Kubernetes
{ hex, ... }:
let
  inherit (hex) toYAMLDoc;
  name = "cert-manager";
  defaults = {
    inherit name;
    namespace = name;
  };
  chart_url = version: "https://charts.jetstack.io/charts/cert-manager-${version}.tgz";
  values_url = "https://github.com/cert-manager/cert-manager/blob/master/deploy/charts/cert-manager/values.yaml";
  chart = hex.k8s._.chart { inherit defaults chart_url; };
  cert-manager = {
    inherit defaults chart chart_url values_url;
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./cert-manager.json; };

    certificate = rec {
      build = args: toYAMLDoc (cert args);
      cert = { name, namespace ? "default", issuer ? "letsencrypt-prod", dns_names ? [ ] }: {
        apiVersion = "cert-manager.io/v1";
        kind = "Certificate";
        metadata = {
          inherit name namespace;
          annotations = { } // hex.annotations;
        };
        spec = {
          secretName = name;
          issuerRef = {
            name = issuer;
            kind = "ClusterIssuer";
          };
          dnsNames = dns_names;
        };
      };
    };
    cluster_issuer =
      let
        acme_servers = {
          prod = "https://acme-v02.api.letsencrypt.org/directory";
          staging = "https://acme-staging-v02.api.letsencrypt.org/directory";
        };
      in
      rec {
        build =
          { email
          , name ? "letsencrypt-prod"
          , ingress_class ? "traefik"
          , acme_server ? if staging then acme_servers.staging else acme_servers.prod
          , staging ? false
          , solvers ? [ ]
          }: toYAMLDoc (issuer { inherit name ingress_class acme_server email solvers; });

        issuer = { name, ingress_class, acme_server, email, solvers }:
          let
            all_solvers = solvers ++ [
              {
                http01 = {
                  ingress = {
                    class = ingress_class;
                  };
                };
              }
            ];
          in
          {
            apiVersion = "cert-manager.io/v1";
            kind = "ClusterIssuer";
            metadata = {
              inherit name;
              annotations = { } // hex.annotations;
            };
            spec = {
              acme = {
                inherit email;
                solvers = all_solvers;
                server = acme_server;
                privateKeySecretRef = {
                  name = "${name}-key";
                };
              };
            };
          };
      };
    # dns solvers
    solvers = {
      route53 = { zone, region, accessKeyID, dns_secret_ref, dns_secret_key }: {
        dns01 = {
          route53 = {
            inherit region accessKeyID;
            secretAccessKeySecretRef = {
              name = dns_secret_ref;
              key = dns_secret_key;
            };
          };
        };
        selector = { dnsZones = [ zone ]; };
      };
      gcp = { gcp_project, dns_secret_ref, dns_secret_key }: {
        dns01 = {
          cloudDNS = {
            project = gcp_project;
            serviceAccountSecretRef = {
              name = dns_secret_ref;
              key = dns_secret_key;
            };
          };
        };
      };
    };
  };
in
cert-manager
