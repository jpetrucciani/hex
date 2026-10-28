# Namespaces with Pod Security Standards labels and optional default-deny, quota, and limit guardrails.
{ hex, pkgs, services, ... }:
let
  inherit (hex) ifNotNull toYAMLDoc;
  inherit (builtins) all attrNames attrValues elem isAttrs isList isString stringLength;
  inherit (pkgs.lib) unique;
  inherit (pkgs.lib.asserts) assertMsg;
  inherit (pkgs.lib.attrsets) filterAttrs;

  context = "hex.k8s.namespaces.build";
  levels = [ "privileged" "baseline" "restricted" ];
  limitFields = [ "default" "defaultRequest" "max" "min" "maxLimitRequestRatio" ];

  isStringAttrs = value: isAttrs value && all isString (attrValues value);
  isLevel = level: level == null || elem level levels;
  isDnsLabel = name:
    isString name && stringLength name <= 63 && builtins.match "[a-z0-9]([-a-z0-9]*[a-z0-9])?" name != null;

  metadata = namespace: name: {
    inherit name namespace;
    inherit (hex) annotations;
  };
in
{
  build =
    { name
    , labels ? { }
    , annotations ? { }
    , enforce ? null              # Pod Security Standard level that rejects pods: privileged, baseline, or restricted
    , warn ? "restricted"         # level reported back to kubectl as warnings
    , audit ? warn                # level recorded in the API server audit log
    , podSecurityVersion ? null   # pin the standard to a Kubernetes minor version like v1.33; null tracks latest
    , defaultDeny ? [ ]           # policy types denied for every pod: [ "Ingress" ], [ "Egress" ], or both
    , dns ? { }                   # services.policies.egress.dns args kept open when Egress is denied; null blocks DNS too
    , quota ? { }                 # ResourceQuota spec.hard, e.g. { "requests.cpu" = "8"; pods = "50"; }
    , limits ? null               # LimitRange Container entry: default, defaultRequest, max, min, maxLimitRequestRatio
    }:
    let
      modes = filterAttrs (_: level: level != null) { inherit enforce warn audit; };
      podSecurityLabels = pkgs.lib.concatMapAttrs
        (mode: level: {
          "pod-security.kubernetes.io/${mode}" = level;
          ${ifNotNull podSecurityVersion "pod-security.kubernetes.io/${mode}-version"} = podSecurityVersion;
        })
        modes;
      denyEgress = elem "Egress" defaultDeny;
      namespace = {
        apiVersion = "v1";
        kind = "Namespace";
        metadata = {
          inherit name;
          labels = labels // podSecurityLabels;
          annotations = annotations // hex.annotations;
        };
      };
      denyPolicy = {
        apiVersion = "networking.k8s.io/v1";
        kind = "NetworkPolicy";
        metadata = metadata name "default-deny";
        spec = {
          podSelector = { };
          policyTypes = defaultDeny;
          ${if denyEgress && dns != null then "egress" else null} = [ (services.policies.egress.dns dns) ];
        };
      };
      resourceQuota = {
        apiVersion = "v1";
        kind = "ResourceQuota";
        metadata = metadata name "default-quota";
        spec.hard = quota;
      };
      limitRange = {
        apiVersion = "v1";
        kind = "LimitRange";
        metadata = metadata name "default-limits";
        spec.limits = [ ({ type = "Container"; } // limits) ];
      };
    in
    assert assertMsg (isDnsLabel name)
      "${context}: name must be a DNS label of at most 63 lowercase alphanumerics or dashes";
    assert assertMsg (isStringAttrs labels && isStringAttrs annotations)
      "${context}: labels and annotations must be attribute sets of strings";
    assert assertMsg (all (key: !(pkgs.lib.hasPrefix "pod-security.kubernetes.io/" key)) (attrNames labels))
      "${context}: set Pod Security labels with enforce, warn, audit, and podSecurityVersion";
    assert assertMsg (isLevel enforce && isLevel warn && isLevel audit)
      "${context}: enforce, warn, and audit must be null, privileged, baseline, or restricted";
    assert assertMsg (podSecurityVersion == null || builtins.match "latest|v1\\.[0-9]+" podSecurityVersion != null)
      "${context}: podSecurityVersion must be null, latest, or a version like v1.33";
    assert assertMsg (isList defaultDeny && all (type: elem type [ "Ingress" "Egress" ]) defaultDeny && defaultDeny == unique defaultDeny)
      "${context}: defaultDeny must be a list of unique Ingress or Egress entries";
    assert assertMsg (dns == null || isAttrs dns)
      "${context}: dns must be null or services.policies.egress.dns arguments";
    assert assertMsg (isStringAttrs quota)
      "${context}: quota must be an attribute set of quantity strings";
    assert assertMsg (limits == null || (isAttrs limits && limits != { } && all (field: elem field limitFields) (attrNames limits) && all isStringAttrs (attrValues limits)))
      "${context}: limits may only contain ${builtins.concatStringsSep ", " limitFields}, each an attribute set of quantity strings";
    ''
      ${toYAMLDoc namespace}
      ${if defaultDeny != [ ] then toYAMLDoc denyPolicy else ""}
      ${if quota != { } then toYAMLDoc resourceQuota else ""}
      ${if limits != null then toYAMLDoc limitRange else ""}
    '';
}
