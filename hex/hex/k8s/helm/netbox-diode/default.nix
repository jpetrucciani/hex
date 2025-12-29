# [netbox-diode](https://github.com/netboxlabs/diode) is a data model and set of ingestion services for NetBox
{ hex, ... }:
let
  name = "diode";
  defaults = {
    inherit name;
    namespace = "default";
  };
  chart_url = version: "https://github.com/netboxlabs/diode/releases/download/helm-chart-diode-${version}/diode-${version}.tgz";
  values_url = "https://github.com/netboxlabs/diode/blob/develop/charts/diode/values.yaml";
  chart = hex.k8s._.chart { inherit defaults chart_url; };
  netbox = {
    inherit defaults chart chart_url values_url;
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./netbox-diode.json; };
  };
in
netbox
