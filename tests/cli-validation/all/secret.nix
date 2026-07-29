{ hex, ... }:
hex.toYAMLDoc {
  apiVersion = "v1";
  kind = "Secret";
  metadata.name = "all-secret";
  stringData.source = "secret.nix";
}
