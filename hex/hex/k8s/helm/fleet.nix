# [fleet](https://github.com/fleetdm/fleet) is an open-source platform for IT, security, and infrastructure teams
{ hex, ... }:
let
  fleet = rec {
    defaults = {
      name = "fleet";
      namespace = "default";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v6-3-0;
      v6-3-0 = _v "v6.3.0" "14k9cxqn8qwyq4m8rzbsvc3nhnqadi4s6hgfqhwp4lc9sjih6x0d"; # 2024-12-19
    };
    chart_url = version: "https://fleetdm.github.io/fleet/charts/fleet-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
fleet
