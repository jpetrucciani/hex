{ hex, pkgs }:
let
  cli = "${hex.hex}/bin/hex";
  grep = "${pkgs.gnugrep}/bin/grep";
  yq = "${pkgs.yq-go}/bin/yq";
  target = ./cli-validation/target.nix;
  invalid = ./cli-validation/invalid.nix;
  customResource = ./cli-validation/custom-resource.nix;
  allTargets = ./cli-validation/all;
  assertYq = expression: message: ''
    if ! ${yq} e -e ${pkgs.lib.escapeShellArg expression} "$rendered" >/dev/null; then
      echo ${pkgs.lib.escapeShellArg message} >&2
      exit 1
    fi
  '';
  assertErrorContains = text: message: ''
    if ! ${grep} -F -- ${pkgs.lib.escapeShellArg text} "$errors" >/dev/null; then
      echo ${pkgs.lib.escapeShellArg message} >&2
      ${pkgs.coreutils}/bin/cat "$errors" >&2
      exit 1
    fi
  '';
  suites = [ "fast" "cli" ];
in
[
  {
    name = "cli-validate-target";
    inherit suites;
    renderCommand = "${cli} --render --validate --verbose --target ${target}";
    expectedDocuments = 1;
    allowMissingSchemas = false;
    check = ''
      ${assertYq ''.kind == "ConfigMap" and .metadata.name == "validation-target"'' "target-file validation did not preserve the rendered resource"}
      if ${grep} -F -- "Summary:" "$rendered" >/dev/null; then
        echo "validation diagnostics leaked into rendered stdout" >&2
        exit 1
      fi
      ${assertErrorContains "against Kubernetes 1.35.0" "target-file validation did not use the default Kubernetes version"}
      ${assertErrorContains "Skipped: 0" "target-file validation unexpectedly skipped a schema"}
    '';
  }
  {
    name = "cli-validate-version-override";
    inherit suites;
    renderCommand = "${cli} --render --validate --verbose --kubeversion 1.34.0 --target ${target}";
    expectedDocuments = 1;
    allowMissingSchemas = false;
    check = ''
      ${assertErrorContains "against Kubernetes 1.34.0" "the Kubernetes version override was not used"}
    '';
  }
  {
    name = "cli-validate-invalid";
    inherit suites;
    renderCommand = "${cli} --render --validate --target ${invalid}";
    expectFailure = "rendered manifests failed Kubernetes 1.35.0 schema validation";
  }
  {
    name = "cli-validate-all";
    inherit suites;
    renderCommand = "cd ${allTargets} && ${cli} --render --validate --all";
    expectedDocuments = 2;
    allowMissingSchemas = false;
    check = ''
      ${assertYq ''select(.kind == "ConfigMap") | .metadata.name == "all-config"'' "--all did not render the ConfigMap fixture"}
      ${assertYq ''select(.kind == "Secret") | .metadata.name == "all-secret"'' "--all did not render the Secret fixture"}
      ${assertErrorContains "Valid: 2" "--all did not validate both rendered resources"}
      ${assertErrorContains "Skipped: 0" "--all unexpectedly skipped a schema"}
    '';
  }
  {
    name = "cli-validate-missing-schema";
    inherit suites;
    renderCommand = "${cli} --render --validate --target ${customResource}";
    expectedDocuments = 1;
    check = ''
      ${assertYq ''.kind == "UnregisteredResource" and .metadata.name == "missing-schema"'' "custom resource output was not preserved"}
      ${assertErrorContains "Skipped: 1" "a missing custom resource schema was not reported as skipped"}
    '';
  }
]
