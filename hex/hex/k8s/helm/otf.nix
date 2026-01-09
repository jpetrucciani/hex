# [otf](https://github.com/jpetrucciani/otf) is an open source terraform cloud alternative
{ hex, ... }:
let
  name = "otfd";
  otf = rec {
    defaults = {
      inherit name;
      namespace = name;
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-3-20;
      v0-3-20 = _v "0.3.20" "1bygm6swvw6vzqh97ak2jzv0yc0i3ywjhijajcbaipbp457in9pb"; # 2025-07-24
      v0-3-19 = _v "0.3.19" "08apvp9ddc7hvm5f9i6y166zch3xly7xqvcv0hyccqbcp9wjhfd7"; # 2025-05-26
      v0-3-18 = _v "0.3.18" "19n3s9j41xi5bcxr99ahkqvfh2zsipar2cydalcjm8pp711lrkj7"; # 2025-05-18
      v0-3-17 = _v "0.3.17" "0r4zjb7y91v14p6qqfxirchy6h1p6mfjrzb10ja8n9npjjh4bvvd"; # 2025-04-25
      v0-3-15 = _v "0.3.15" "1qgsw6jlp8w7zaxa5k0v3rhg9v6djdmx7g0pbz6g0b6c7r8f26ah"; # 2025-04-16
      v0-3-14 = _v "0.3.14" "15f7imbsdmw31vbkm7lisyf4dzzbiql6glb9zsp3n07ihvi13v5n"; # 2025-01-03
      v0-3-13 = _v "0.3.13" "0769y1554cgajpa19987xwwpg4pikgk8c0l69s6b5kpyyw3k2cjc"; # LEGACY JACOBI FORK
    };
    chart_url = version: if version == "0.3.13" then "https://github.com/jpetrucciani/otf-charts/releases/download/otf-${version}/otf-${version}.tgz" else "https://github.com/leg100/otf-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
otf
