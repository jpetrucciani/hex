# [Authentik](https://github.com/goauthentik/authentik) is an open source IDP written in go
{ hex, ... }:
let
  authentik = rec {
    defaults = {
      name = "authentik";
      namespace = "default";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v2025-8-4;
      v2025-8-4 = _v "2025.8.4" "1zzhpvg09zbjjarlrgdm3rwig740wkgmxv291179j4iqnyjzpg1d"; # 2025-09-30
      v2025-8-3 = _v "2025.8.3" "07hf5q2lq4dkksh44xkkiygj8ab4c36zz5czbba72i79lskm791g"; # 2025-09-16
      v2025-8-2 = _v "2025.8.2" "0i6g8zpaxjs6gr2ksgn5896sip4awn6r0c8ylba0iajlsqpd157y"; # 2025-09-15
      v2025-8-1 = _v "2025.8.1" "1k9hxfc1cclq0nfpywv51rf6b00qnkpns8pb0xmy1yfcvqxa7rr5"; # 2025-08-22
      v2025-8-0 = _v "2025.8.0" "0w2k4sm32xral7dm8yxsnj3bh06nbrqz24fkigj5910zfyxryrcb"; # 2025-08-20
      v2025-6-4 = _v "2025.6.4" "0vk1660qc9rarar855vbdmk8yvdll6ifmaskrf4b3clrn7qg9dfi"; # 2025-07-22
      v2025-6-3 = _v "2025.6.3" "0j198nv0v42279r6wfjnb5670l8gmqfnccp570z597x6nl1jwc18"; # 2025-06-27
      v2025-6-2 = _v "2025.6.2" "08lyc7z8wcvdmzbcx995b2rvr4dn6x9b2j92py1338qirmh5wh0s"; # 2025-06-17
      v2025-6-1 = _v "2025.6.1" "0yw1j4p00pn8pnlhkg07y74ffkmiq985mv1gwz1y576aacvqxx6p"; # 2025-06-06
      v2025-6-0 = _v "2025.6.0" "046v1zmwrasbgnjqs6rpwca7rpg39wq39cs1a0xxv1zs8s814lbn"; # 2025-06-04
      v2025-4-1 = _v "2025.4.1" "0pvxdc8z28k3b2qvzjr5py5igk0n2hgczw7gb2x6chfqc3l1cixv"; # 2025-05-15
      v2025-4-0 = _v "2025.4.0" "1dz89cih297dff9fw904klyw689mrxcqmmhwjv8zfriw7gghmrn2"; # 2025-04-30
      v2025-2-4 = _v "2025.2.4" "0df60rxlpjajzc6qy6nlcdaj4j49vznrlfj0ixhrh4zdxlds065s"; # 2025-04-08
      v2025-2-3 = _v "2025.2.3" "1xi6780517sh12lq6dxsh5qmxfcrgvqfz2a6k04ibb55dnfs406f"; # 2025-03-28
      v2025-2-2 = _v "2025.2.2" "1nz8ikpckiip7xlxhwaylihjcs9w7frz7d8ridc7askwknj826g0"; # 2025-03-18
      v2025-2-1 = _v "2025.2.1" "0rs6ry327g1kijcwb1mwychqxmh997sh77afssv6jn5sl408c0x3"; # 2025-02-26
      v2025-2-0 = _v "2025.2.0" "1h9pg6z81f04fzrln1d4l8m76ypb4qrwbafs4qmd9s0njzimy2qn"; # 2025-02-24
      v2024-12-3 = _v "2024.12.3" "1pcbh5zf0f7fp8i6f0dn81lar13z8gfh2l2acwqq6km8rfgl0801"; # 2025-01-29
      v2024-12-2 = _v "2024.12.2" "1k0qq53s6wsragsy3p1svsabkcw8wy3xzw0xc0psrm7ym5yacm2i"; # 2025-01-09
      v2024-12-1 = _v "2024.12.1" "1z8iahjdqjp5pzjb17c8k590wskzx22w6g088ncq9b8q4m10zwap"; # 2024-12-23
      v2024-12-0 = _v "2024.12.0" "0x2vz7v7n7z2dv9n37c3asjgw0zjfyn7vwycvip4g36wrbbzjbb0"; # 2024-12-19
      v2024-10-5 = _v "2024.10.5" "1mvwq75p7hhsc8id1zs1glzf20b9c8hs3xpmajj9pp1sdjsdbc60"; # 2024-12-10
      v2024-10-4 = _v "2024.10.4" "1nb2fpv2qqhcx66sigx4rpasrkrb72s8wyx3m13wl8s3c9fhbhf0"; # 2024-11-21
      v2024-8-4 = _v "2024.8.4" "1rw0kr73z6s0jv5i55b6h3acg14z7frr865zlqnm248m06m2jqs1"; # 2024-10-30
      v2024-6-4 = _v "2024.6.4" "0ah2l6b1rllq2xnbgcc754pk81pa3ns9cbkwhc6rvaw2qay07wqs"; # 2024-08-22
      v2024-4-2 = _v "2024.4.2" "0in142g0swzn55acll4pcidgqiyxyavbm9gn00dajj8ylcrjz30a"; # 2024-05-07
      v2024-4-1 = _v "2024.4.1" "0890nfigg5x0wds35fzvzmn2l57zad3hv64gaijapwzr8ff63c6i"; # 2024-04-26
      v2024-2-3 = _v "2024.2.3" "046hsz0bn2mf8c12lapkwdznk91l9zq0cjr8wy48nzam88lhzcs9"; # 2024-04-17
      v2024-2-2 = _v "2024.2.2" "0dqs43sxva6n3xnsgmqs28854wl4jy0lcw8czajpch2mzdqsdwhc"; # 2024-03-04
      v2024-2-1 = _v "2024.2.1" "17fgvarciwnrp02s420bgbizqb0lyglvzqgkjl3i6gnnazgc395a"; # 2024-02-22
      v2024-2-0 = _v "2024.2.0" "0dssij0lcr3qlql10aydwd8z4s3j5lw0ykdlrcfr3xq58p59hm2g"; # 2024-02-21
    };
    chart_url = version: "https://github.com/goauthentik/helm/releases/download/authentik-${version}/authentik-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
authentik
