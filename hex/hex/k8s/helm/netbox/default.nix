# [netbox](https://netboxlabs.com/products/netbox/) is an IP address management (IPAM) and data center infrastructure management (DCIM) tool
{ hex, ... }:
let
  name = "netbox";
  defaults = {
    inherit name;
    namespace = "default";
  };
  chart_url = version: "https://github.com/netbox-community/netbox-chart/releases/download/netbox-${version}/netbox-${version}.tgz";
  values_url = "https://github.com/netbox-community/netbox-chart/blob/main/charts/netbox/values.yaml";
  chart = hex.k8s._.chart { inherit defaults chart_url; };
  netbox = {
    inherit defaults chart chart_url values_url;
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./netbox.json; };
  };
in
netbox
