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
      latest = v2025-2-1;
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
      v2023-10-7 = _v "2023.10.7" "1akcij9kkplsx7jhlvbckcx0cvsqizr6ahglxw535r7f519cmnhd"; # 2024-01-29
      v2023-10-6 = _v "2023.10.6" "1pfjbz5ll3fgqw4qh4axri8fb11kjcf771zi09lxj2jxki6c9m36";
      v2023-8-3 = _v "2023.8.3" "1n0pqzmnypls3s9gggnsnyapi2b96isyd8p3x0cvzrysx5ah9ql1";
      v2023-6-3 = _v "2023.6.3" "0wz502fd327wqq3pdamm19gkz9isrj0ldqya5ksbmbjdhcb8jzwp";
      v2023-5-5 = _v "2023.5.5" "1ijg0qcc8ff7552yvn8340s8fdgvcwsjbjg3y11r7qbywnwjn4pl";
      v2023-4-1 = _v "2023.4.1" "0m02dvvrhfx02kk8y2zdjgqyra0q600477bp30n5zcv0r4kxqphz";
      v2023-3-1 = _v "2023.3.1" "0jgh96b28xfn37bg16n4ypw5m7i4x9b7y2f26f47nsf5vvcm0d75";
      v2023-2-4 = _v "2023.2.4" "03li78dnzbdlaqbinqkjqfk2fzk8m5xy0jq2n5b573r5ann51dpd";
      v2023-1-2 = _v "2023.1.2" "1vym8san70qcqxbfphvv3f8q09f1yf67pf9vx2zc3yl0dziv76qj";
      v2022-12-4 = _v "2022.12.4" "12s7qd09sz3mwxi7zg4406lgyy06qbg0l9ky2si8lcnsbmxj0g6f";
      v2022-11-4 = _v "2022.11.4" "19r6pw48mdd9l9b0k5slqnhqnj4ybv997n5nzkamnv8c0x09jka8";
      v2022-10-0 = _v "2022.10.0" "0k6m6zi0pjihl1wqzrm7akymzswlqbg9qpf9f6fz3wicj63cj6bv";
      v2022-9-0 = _v "2022.9.0" "1r8hnacfl70ih5d3vqp6zk2c94gffqimmj4cw5g4lbri65gzgl1l";
      v2022-7-3 = _v "2022.7.3" "05vv6wjyf1vkfy2qmp4yshb4pxyg246fkpc6v6gp3b5h5y55ds30";
    };
    chart_url = version: "https://github.com/goauthentik/helm/releases/download/authentik-${version}/authentik-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
authentik
