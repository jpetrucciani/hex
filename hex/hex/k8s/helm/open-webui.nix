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
      latest = v6-1-0;
      v6-1-0 = _v "6.1.0" "0yn01fx81mfypwq78p01wk3hamxrv69vpb0626lng347q6lf8bpz"; # 2025-04-06
      v6-0-0 = _v "6.0.0" "035qdnwx949yri26z2099cx74kb9h67bd2icczb48yql9b1994x9"; # 2025-04-01
      v5-25-0 = _v "5.25.0" "19v1nz8avpwzgqqlyi261l8kc6nkv9rh79xxzs21cj14z4sn8zd5"; # 2025-03-19
      v5-24-0 = _v "5.24.0" "0kc06z0fyqmgvh0m5c8a87vpr22wiwh3lf0zw7kksbqsdpiyj0kg"; # 2025-03-13
      v5-23-0 = _v "5.23.0" "14ag774lpqzb8gw3w4ah7cdb5cx5bmmknvvhcwa8fm5czlwv3jkd"; # 2025-03-13
      v5-22-0 = _v "5.22.0" "06i0xll5i8rshi17lq70pigali2p78gddsk28h66mwhl9v0vdd7q"; # 2025-03-12
      v5-21-0 = _v "5.21.0" "1yzr1jkwlsk3z84w2ci4ync1zrckqpyj68xlkz2m1im4m29garn8"; # 2025-03-11
      v5-20-0 = _v "5.20.0" "1zkq836n0kj2ch169f71xmfrv8v06wvpzm3nnzfrn642abzaxvqx"; # 2025-02-25
      v5-19-0 = _v "5.19.0" "117jj41lysgszc1ffrjv032mq1103qjfsjrdskwrcya55ivdgq0g"; # 2025-02-21
      v5-18-0 = _v "5.18.0" "0ppxzzl5jxk4jw2ail5rzdsvc2c8cw42livll3g6kyw4lv3wykps"; # 2025-02-21
      v5-17-0 = _v "5.17.0" "1sa0nsx7naylnhi5jdgm5zr5vcfys9w3z1z7zs4szqb8rbk6pk3c"; # 2025-02-20
      v5-16-1 = _v "5.16.1" "151rzkfwqlj1kln9gc7x5rsl20144nxc72gk6799nhg2v7y12hca"; # 2025-02-19
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
