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
      latest = v8-12-2;
      v8-12-2 = _v "8.12.2" "1zn5hn2261fk0q2m31ydldmb1pczcs5iagyb4wvrhhybr9sqmm6a"; # 2025-10-18
      v8-12-1 = _v "8.12.1" "1gzf8465pwvqfqmh6vpyn9nzzdckijx1lww8spiyrxp7vjzkxcbw"; # 2025-10-18
      v8-12-0 = _v "8.12.0" "09rlblnihnbrq9hxjqgdxcmmm6aipipyb3pij3qs2cl7cjh0h5qz"; # 2025-10-18
      v8-11-0 = _v "8.11.0" "0a1p9fr7z0rrss6v9q56caw702hcnk56dl9gadb5q625saxnjy3c"; # 2025-10-14
      v8-10-0 = _v "8.10.0" "0bmdsxybqcpdkq4w7ga64w1f8qy4ab71q6gbxym41jczbny33prb"; # 2025-10-07
      v8-9-0 = _v "8.9.0" "0yg219nj5n08nz1cfxhccpgpsranihx2315adbpcmci8qjxb4grc"; # 2025-10-01
      v8-8-0 = _v "8.8.0" "0lmmrbivcwcppl5gir82f3bi8dsiqfv17pg0siydf9dwpypnlgsl"; # 2025-09-29
      v8-7-0 = _v "8.7.0" "1837bi4v0hid54v5cgjkchicwdjsidis8m7jarr1b06ibcxpy4yi"; # 2025-09-26
      v8-6-0 = _v "8.6.0" "0m41h5hc4vv3fhp2lrd3jvm3lxx4jq2rgkzs5l87n9dag9171nc0"; # 2025-09-17
      v8-5-0 = _v "8.5.0" "0035q38l36g14wfry3ypx6xq3s3ksy7map52j7g0rk0w77dgbcn2"; # 2025-09-17
      v8-4-0 = _v "8.4.0" "0l02gr6syywvxzj8bwfklvc7qfqlcwpympwjj0q7vnvyxyainw2f"; # 2025-09-10
      v8-3-0 = _v "8.3.0" "02gpaldaddnpk2144lj1w62h2zmck4ryp8hk4x14cp1h1k1mfbmq"; # 2025-09-09
      v8-2-0 = _v "8.2.0" "0vacmgnf6z1qlyngwr1731zllsna8a48ywsizlrkzycbyxzi41qz"; # 2025-09-08
      v8-1-0 = _v "8.1.0" "029m5lvjdk82xi47rjvkzf6xyk8dqs76fxmb3cm0j1w8mlib8ld8"; # 2025-09-05
      v8-0-0 = _v "8.0.0" "1w60dw73dply0y04vy9vfpn0ag5f6d2zz20kkl9p5phcpdgyx780"; # 2025-09-04
      v7-7-0 = _v "7.7.0" "04lavh4lxvb2nwsp44ccxb6kmvwgvan9mi8wv1safmx2dxzqhp5p"; # 2025-08-28
      v7-6-0 = _v "7.6.0" "08881apglq212byxlq8w2ihvdi33xdks5808bccb9x2gmvyjmcji"; # 2025-08-23
      v7-5-0 = _v "7.5.0" "0xa22r75r8x2ipd71w1kgmfxxj0f7bzj9n06xsda3nbri56nsimx"; # 2025-08-22
      v7-4-0 = _v "7.4.0" "13bsj62ax02y1m6xg7y1ia1drnq90c3mcajvqrk2vqwcq3d4lwwr"; # 2025-08-22
      v7-3-0 = _v "7.3.0" "10hnmhkxmlhdczmbphncvdklmcksm7pf6385n1jgg451x4fsr8g2"; # 2025-08-14
      v7-2-0 = _v "7.2.0" "0lqkxmsdvrbybpb9y85s9qxzf13rgxlwgyqajiiypzannah6y027"; # 2025-08-08
      v7-1-0 = _v "7.1.0" "0ycrlzx7wbl4qvcz7rkjkb758k9ygdbf3i9s9bczjlwpk478f5yx"; # 2025-08-08
      v7-0-1 = _v "7.0.1" "1f0gslq608zags9h31rd1s13ilnpy8xpfvaa56vf48rsvydddnpy"; # 2025-07-31
      v7-0-0 = _v "7.0.0" "08vz9jscv2jb0w3ac61r565y11c9idphhyn77ka6bbd2hydnrk7s"; # 2025-07-29
      v6-29-0 = _v "6.29.0" "1286sxyhgqadbfw8jb80wa3a67kzwpyv1xzjf1y9kadnzf3zmcai"; # 2025-07-23
      v6-28-0 = _v "6.28.0" "051pvzkbifkhmn5pfl85h5vlclvqgv2dr0jdy4di6lkw4qvqlwni"; # 2025-07-21
      v6-27-0 = _v "6.27.0" "1b83rc62q7365hwiqqzr9m982wvw3grbwxajcx495h5bbgrswmmw"; # 2025-07-21
      v6-26-0 = _v "6.26.0" "17b95cni1jzqig7bzbpnvlr2rndfcjymi277rcn5m97w4898bzw5"; # 2025-07-20
      v6-25-0 = _v "6.25.0" "0m6qzppagckaispnnaaq14sywidj9fsl4d0rlc6rlbxzy1acnbna"; # 2025-07-20
      v6-24-0 = _v "6.24.0" "0mlpnk64cd1i85lyqsj4vf5ki5gchrmzgg9jxdma8paq4kaa3nzg"; # 2025-07-15
      v6-23-0 = _v "6.23.0" "0r3bxyby0fg1571a70inarmnbyvzp83i53n7xdk5v8qgn0f3f8j1"; # 2025-07-14
      v6-22-0 = _v "6.22.0" "15b8crngb1j8sa4gsfm77dsaxf471jqaj77rv6qdygimkkbgm1c6"; # 2025-06-19
      v6-21-0 = _v "6.21.0" "08b4x6wwlskkpnbyi5zcx041ij26n5fcqd1f2hcymd26ff3fs8sl"; # 2025-06-17
      v6-20-0 = _v "6.20.0" "17s1xcidg163757s59jqyn3f31xfn5qkdl434fwpkxhnsij3cqdp"; # 2025-06-11
      v6-19-0 = _v "6.19.0" "17ypm3n63yi1ygldh1q4iz8qxy98580r4pa03xxvxh7lj404gr20"; # 2025-05-30
      v6-18-0 = _v "6.18.0" "19d63gkmj3zli9lcghm4l7bmh3nf7l99r3c2ad7facm43c31lsvz"; # 2025-05-30
      v6-17-0 = _v "6.17.0" "1070w40y02qh374y9gg8fq2y3lh32a8hhknb84pazi05iybam36v"; # 2025-05-28
      v6-16-0 = _v "6.16.0" "032fhrbdj3rqxlc9brnqxbwi6s5fis6a0if57lr6ik27pa8982wj"; # 2025-05-19
      v6-15-0 = _v "6.15.0" "1znvjy451bsfzj3id65r3yd32lljp4ch94i4ss8mssiamn560shw"; # 2025-05-16
      v6-14-0 = _v "6.14.0" "1yhbcdqgxrbj59zd1qrcsk59p58ms2arscycg2y2f0hd2p4462zr"; # 2025-05-15
      v6-13-0 = _v "6.13.0" "0i67jf7229v5xs6mdjyjppdla0kggg6l0291dp4ghx5b9iczyr96"; # 2025-05-09
      v6-12-0 = _v "6.12.0" "0cf7fv7whb4x8rgv421sb36l7ak05vlcv2lf6zq0flnd9rpjhqr7"; # 2025-05-09
      v6-11-0 = _v "6.11.0" "1kcai0diyv2kkikf1f41dkkax25qgdwhqdps9waz6y56ixp9mqdm"; # 2025-05-07
      v6-10-0 = _v "6.10.0" "0qc2r088kz68ag58b3nfjg58lgb9mxlc0i5pfm74b83jln7arsk4"; # 2025-05-07
      v6-9-0 = _v "6.9.0" "0d72wcgr8bnpc8xwa733hbl25m4782ra9wlk1q1xsdcglxdmi03d"; # 2025-05-06
      v6-8-0 = _v "6.8.0" "1rrxhvsy5r4vgmv1j6hzc4x3d3cz7bg35mjmmscq7bxibpg75jm5"; # 2025-05-06
      v6-7-0 = _v "6.7.0" "04l3bjyfwbmf3x0z2q2x93vclacm0gffcrp7wi3fzv1var9sibz9"; # 2025-05-06
      v6-6-0 = _v "6.6.0" "19pwlv8n0szx3k1l5bwwcbs8cf38rwbjhz9cvdvsfryfdbc40gnd"; # 2025-05-05
      v6-5-0 = _v "6.5.0" "183m5j9v0mwqss25rqh2il0cjgj9fx5qq4bxsrgvzwqp4kjqm795"; # 2025-05-05
      v6-4-0 = _v "6.4.0" "0j343im22lc8cv9as0bblz30kp18vk2m3lm2afa4v6wdqjswwspn"; # 2025-04-16
      v6-3-0 = _v "6.3.0" "0g8wahmvvkkrd9gf108w4fn3ib7f46s6sh4sfzsnzjmz0b1m40mf"; # 2025-04-13
      v6-2-0 = _v "6.2.0" "15qh046y06l89596ih5p1rxbsa96zqipidmnmcmbizy1bmmkschj"; # 2025-04-13
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
