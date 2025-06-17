# 
{ hex, ... }:
let
  namespace = "coroot";
  coroot-operator =
    let
      name = "coroot-operator";
    in
    rec {
      __functor = _: version.latest;
      defaults = {
        inherit name namespace;
      };
      version = rec {
        _v = hex.k8s._.version chart;
        latest = v0-3-2;
        v0-3-2 = _v "0.3.2" "1qz8ghnw9pagn2mwykrh0qy6p6kahh6kp52w7jm09whx4kfq6vmd"; # 2025-05-19
      };
      chart_url = version: "https://github.com/coroot/helm-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
  coroot-ce =
    let
      name = "coroot-ce";
    in
    rec {
      __functor = _: version.latest;
      defaults = {
        inherit name namespace;
      };
      version = rec {
        _v = hex.k8s._.version chart;
        latest = v0-3-1;
        v0-3-1 = _v "0.3.1" "0n7j64hsfz3a8cj2yybqdrgfg0x1c46d5w9m36iwxgcsc31p05l2"; # 2025-01-15
      };
      chart_url = version: "https://github.com/coroot/helm-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
  node-agent =
    let
      name = "node-agent";
    in
    rec {
      __functor = _: version.latest;
      defaults = {
        inherit name namespace;
      };
      version = rec {
        _v = hex.k8s._.version chart;
        latest = v0-2-20;
        v0-2-20 = _v "0.2.20" "0qgzizcjqvif9fc4r74pfq0knfx5mm2q3mpx5afsbg9n059v65x4"; # 2025-06-05
      };
      chart_url = version: "https://github.com/coroot/helm-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
in
{
  inherit coroot-ce coroot-operator node-agent;
}
