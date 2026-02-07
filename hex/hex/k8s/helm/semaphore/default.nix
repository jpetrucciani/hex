# This module contains a [semaphore](https://github.com/semaphoreui/semaphore) chart
{ hex, ... }:
let
  semaphore = rec {
    defaults = {
      name = "semaphore";
    };
    values_url = "https://github.com/semaphoreui/charts/blob/main/stable/semaphore/values.yaml";
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./semaphore.json; };
    chart_url = version: "https://github.com/semaphoreui/charts/releases/download/semaphore-${version}/semaphore-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
semaphore
