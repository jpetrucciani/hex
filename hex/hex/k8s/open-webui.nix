# [open-webui](https://github.com/open-webui/open-webui) is a user-friendly AI interface
{ hex, ... }:
let
  name = "open-webui";

  # example values file here: https://github.com/open-webui/helm-charts/blob/main/charts/open-webui/values.yaml
  open-webui = rec {
    defaults = {
      inherit name;
      namespace = "default";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v4-0-0;
      v4-0-6 = _v "4.0.6" "1z97b6fb61bki224b2az9c281i2ldfval8b92dywqf8mjsmhflml"; # 2024-12-02
      v4-0-0 = _v "4.0.0" "16g43mwla6mlgyn6jm8iajav31rk9435xyh7kfq5qjlin7w6gmcx"; # 2024-11-20
      v3-6-0 = _v "3.6.0" "0qkzxcvbf38j9naxgl19m6v6nyl2308a58j5nx1yvhkikrqikf6k"; # 2024-11-07
      v3-5-1 = _v "3.5.1" "1akgy4v47a168cl6wzhk1n7dkn24bpdg7id7xigf9zyxfd7vdx7d"; # 2024-11-05
      v3-4-3 = _v "3.4.3" "0q2ylkhn9v0v8m2bscjzw26q8rv38dsblh5x7v3hzbqxi09pdj4w"; # 2024-10-27
      v3-3-2 = _v "3.3.2" "0p7yg4lqips9krvcbzflva9dldqbnf71v3dz64zl744l928635mp"; # 2024-10-08
    };
    chart_url = version: "https://github.com/open-webui/helm-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
    chart = hex.k8s._.chart {
      inherit defaults chart_url;
    };
  };
in
open-webui
