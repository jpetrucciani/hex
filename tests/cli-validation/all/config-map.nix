{ hex, ... }:
hex.toYAMLDoc {
  apiVersion = "v1";
  kind = "ConfigMap";
  metadata.name = "all-config";
  data.source = "config-map.nix";
}
