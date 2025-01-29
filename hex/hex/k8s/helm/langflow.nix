# [langflow](https://github.com/langflow-ai/langflow) is a visual framework for building multi-agent and RAG applications
{ hex, ... }:
let
  namespace = "langflow";
  langflow_chart_url = name: version: "https://github.com/langflow-ai/langflow-helm-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
  ide =
    let
      name = "langflow-ide";
    in
    rec {
      defaults = {
        inherit name namespace;
      };
      version = rec {
        _v = hex.k8s._.version chart;
        latest = v0-1-1;
        v0-1-1 = _v "0.1.1" "0kwniaplpl0h6h9qslkv3k7c8q7dzy8mwhl9zfp16sgfa0s88ywy"; # 2025-01-24
        v0-1-0 = _v "0.1.0" "016kii40x2hdzrhphl7l8jas9ikn8ykw4y0k21z95k3cljignhys"; # 2024-07-23
      };
      chart_url = langflow_chart_url name;
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
  runtime =
    let
      name = "langflow-runtime";
    in
    rec {
      defaults = {
        inherit name namespace;
      };
      version = rec {
        _v = hex.k8s._.version chart;
        latest = v0-1-1;
        v0-1-1 = _v "0.1.1" "16mkv0ajma6j65df46p351jxzjdfykns07q4yavja9qdrcc8nbsy"; # 2025-01-24
        v0-1-0 = _v "0.1.0" "009xdwpwr9i4r7rpmkfijmiaqc2gjwy7nkg9rzgyisxg8gq8xgmg"; # 2024-07-23
      };
      chart_url = langflow_chart_url name;
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
in
{ inherit ide runtime; }
