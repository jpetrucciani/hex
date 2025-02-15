# [open-webui](https://github.com/open-webui/open-webui) is a user-friendly AI interface
{ hex, ... }:
let
  name = "open-webui";

  # example values file here: https://github.com/open-webui/helm-charts/blob/main/charts/open-webui/values.yaml
  open-webui = rec {
    defaults = {
      inherit name;
      namespace = "default";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v5-13-0;
      v5-13-0 = _v "5.13.0" "0n7bskzwf0gc7c9qkmk2znxsfkkahwczzlqv623svqmzm33qpzx7"; # 2025-02-14
      v5-12-0 = _v "5.12.0" "0mi6263yjvc3m1xcdanli648r9r6456hy5nhsasmx9j2v80b3425"; # 2025-02-14
      v5-11-0 = _v "5.11.0" "00l173d0bgah7mq5gc8fk2xxm66kxajh0ckjp71l66pkm211mdp3"; # 2025-02-13
      v5-10-1 = _v "5.10.1" "1q08lhpxrlnwpnhbh8jgpk1anskbsglc2fj1ahcc2kg3iqbdgjq2"; # 2025-02-10
      v5-10-0 = _v "5.10.0" "1snyxvad8f2bdfajw1gkd8rdmi2hr76fngnkdbgvbc4r2h9flqkk"; # 2025-02-06
      v5-4-0 = _v "5.4.0" "0qql608ygafyyaa7iilikg345q6jl8bn8429f13bjyj6n7ac0mvw"; # 2025-01-16
      v5-2-0 = _v "5.2.0" "1iq87s4siqd5mc9ads9x1hb7my5nwbmqxg1x011qy9fkn86n2pig"; # 2025-01-14
      v5-1-1 = _v "5.1.1" "17c0c3kkc1i1y2w645l9z6sjb7cw30cwzjb25ab6k2n4fxjn625s"; # 2025-01-05
      v5-1-0 = _v "5.1.0" "1plbz5bff6flb0ydpjg8j88vlm0fb9w9vyqvyw6z54vj7z8lirn1"; # 2025-01-03
      v5-0-0 = _v "5.0.0" "1k9qfx5jwfd3y6nphyw2b00qz3af6na1kkjak96k2pw110mp3i0x"; # 2024-12-27
      v4-1-0 = _v "4.1.0" "0ckafal4psw1c9cqzq9kgg8s7jgvs67gnwgyv3z5536zk9izyifc"; # 2024-12-13
      v4-0-7 = _v "4.0.7" "1xlc2qq01ifgdvl24l7kmz4lqcj6j372djqi02z4qa15wzzywj66"; # 2024-12-13
      v4-0-6 = _v "4.0.6" "1z97b6fb61bki224b2az9c281i2ldfval8b92dywqf8mjsmhflml"; # 2024-12-02
      v4-0-0 = _v "4.0.0" "1p68zhpvcdfqkmpqvd91mazs2qdhyjcc7xnrfjc3s67rgbw4cl42"; # 2024-11-20
      v3-6-0 = _v "3.6.0" "0qkzxcvbf38j9naxgl19m6v6nyl2308a58j5nx1yvhkikrqikf6k"; # 2024-11-07
      v3-5-1 = _v "3.5.1" "1akgy4v47a168cl6wzhk1n7dkn24bpdg7id7xigf9zyxfd7vdx7d"; # 2024-11-05
      v3-4-3 = _v "3.4.3" "0q2ylkhn9v0v8m2bscjzw26q8rv38dsblh5x7v3hzbqxi09pdj4w"; # 2024-10-27
      v3-3-2 = _v "3.3.2" "0p7yg4lqips9krvcbzflva9dldqbnf71v3dz64zl744l928635mp"; # 2024-10-08
    };
    chart_url = version: "https://github.com/open-webui/helm-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
    chart = hex.k8s._.chart {
      inherit defaults chart_url;
    };
  };
in
open-webui
