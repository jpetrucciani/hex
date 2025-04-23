# This module contains a [csi-driver-smb](https://github.com/kubernetes-csi/csi-driver-smb) chart
# values here: https://github.com/kubernetes-csi/csi-driver-smb/blob/master/charts/v1.7.0/csi-driver-smb/values.yaml
{ hex, ... }:
let
  remove_driver_ns = hex.yq_magic.delete_key ''.kind == "CSIDriver"'' ''.metadata.namespace'';
  csi-driver-smb = rec {
    defaults = {
      name = "csi-driver-smb";
      namespace = "kube-system";
      postRender = "${remove_driver_ns} $out";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v1-17-0;
      v1-17-0 = _v "v1.17.0" "1wswi2nnccy0lwc4212cbdwj63h75qwff4wc2vqvj8sy7f8l6x9q"; # 2025-01-23
    };
    chart_url = version: "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts/${version}/csi-driver-smb-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
csi-driver-smb
