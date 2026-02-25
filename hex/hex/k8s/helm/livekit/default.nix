# [livekit](https://github.com/livekit/livekit) is an End-to-end realtime stack for connecting humans and AI
{ hex, ... }:
let
  # values here: https://github.com/livekit/livekit-helm/blob/master/livekit-server/values.yaml
  name = "livekit";
  livekit = rec {
    defaults = {
      inherit name;
      namespace = "default";
    };
    version = hex.k8s._.versionMap { inherit chart; versionFile = ./livekit.json; };
    chart_url = version: "https://helm.livekit.io/livekit-server-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
    values_url = "https://github.com/livekit/livekit-helm/blob/master/livekit-server/values.yaml";
  };
in
livekit
