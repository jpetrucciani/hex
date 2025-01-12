# This module contains an [odoo](https://github.com/odoo/odoo) chart
{ hex, ... }:
let
  odoo = rec {
    defaults = {
      name = "odoo";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-2-2;
      v0-2-2 = _v "0.2.2" "1ylcj9rdviqdi9y0nwsf8wwgxdxjvcnnclnzhfrkq193c9c3p8c1"; # 2024-12-20
    };
    chart_url = version: "https://imio.github.io/helm-charts/odoo/odoo-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
odoo
