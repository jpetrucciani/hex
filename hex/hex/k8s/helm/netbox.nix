# [netbox](https://netboxlabs.com/products/netbox/) is an IP address management (IPAM) and data center infrastructure management (DCIM) tool
{ hex, ... }:
let
  # values here: https://github.com/netbox-community/netbox-chart/blob/main/charts/netbox/values.yaml
  name = "netbox";
  netbox = rec {
    defaults = {
      inherit name;
      namespace = "default";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v7-2-16;
      v7-2-16 = _v "7.2.16" "1vnar1p7vf6c0a8fxilcjq5580mid50211q2jys34329qfkyigwq"; # 2025-12-08
    };
    chart_url = version: "https://github.com/netbox-community/netbox-chart/releases/download/netbox-${version}/netbox-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
netbox
