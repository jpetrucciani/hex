{ hex, ... }:
hex.toYAMLDoc {
  apiVersion = "v1";
  kind = "ConfigMap";
  metadata.name = "validation-target";
  data.valid = "true";
}
