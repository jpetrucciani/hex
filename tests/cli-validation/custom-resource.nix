{ hex, ... }:
hex.toYAMLDoc {
  apiVersion = "testing.hex.invalid/v1";
  kind = "UnregisteredResource";
  metadata.name = "missing-schema";
  spec.enabled = true;
}
