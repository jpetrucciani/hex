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
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v1-9-0;
      v1-9-0 = _v "1.9.0" "07nv92khwx171iz4gzi521sxgx8lz08kp8zxjgygjqa4w61hmcs9"; # 2025-06-04
    };
    chart_url = version: "https://helm.livekit.io/livekit-server-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
livekit
