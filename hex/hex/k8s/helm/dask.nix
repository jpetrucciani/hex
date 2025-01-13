# [dask](https://docs.dask.org/en/stable/) is a python library/framework for parallel and distributed computing 
{ hex, ... }:
let
  namespace = "dask";
  kubernetes-operator =
    let
      # https://docs.dask.org/en/stable/deploying-kubernetes.html
      name = "dask-operator";
    in
    rec {
      __functor = _: version.latest;
      defaults = {
        inherit name namespace;
      };
      version = rec {
        _v = hex.k8s._.version chart;
        latest = v2024-9-0;
        v2024-9-0 = _v "2024.9.0" "082g2dbniwgir68ad9j02rd3hx068fplzlv7b00nbgh3ddxq7kmc"; # 2024-09-18
        v2024-8-0 = _v "2024.8.0" "1b4hi9b4nhmfywfghs0r8ql7y2m8dpxi3bl38vjaqpkxi86fdsjn"; # 2024-08-22
        v2024-5-0 = _v "2024.5.0" "1xryp51dn0w9yma914s4ggbrhxmdfay4gzgscyng33i1zdd7zbdl"; # 2024-05-01
      };
      chart_url = version: "https://helm.dask.org/dask-kubernetes-operator-${version}.tgz";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
in
{
  inherit kubernetes-operator;
}