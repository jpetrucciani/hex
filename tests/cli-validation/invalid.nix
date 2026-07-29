{ hex, ... }:
hex.toYAMLDoc {
  apiVersion = "apps/v1";
  kind = "Deployment";
  metadata.name = "invalid-validation-target";
  spec.replicas = "many";
}
