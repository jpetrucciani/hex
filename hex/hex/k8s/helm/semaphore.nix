# This module contains a [semaphore](https://github.com/semaphoreui/semaphore) chart
{ hex, ... }:
let
  semaphore = rec {
    defaults = {
      name = "semaphore";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v16-0-0;
      v16-0-0 = _v "16.0.0" "0hc8mbb3cnk1yqr5hbyzkdniv35barkpxh1d9m64pb5vb125af6y"; # 2025-06-14
      v15-1-6 = _v "15.1.6" "1nyy5iq5wj8b39v1xzxy25by38wsw3zsp65wb964vdn83b8bps9a"; # 2025-05-06
    };
    chart_url = version: "https://github.com/semaphoreui/charts/releases/download/semaphore-${version}/semaphore-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
semaphore
