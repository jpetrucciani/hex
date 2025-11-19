# Helpers for [prometheus](https://github.com/prometheus/prometheus) related things in k8s land!
{ hex, ... }:
let
  inherit (hex) ifNotEmptyList ifNotNull toYAMLDoc;
  prom_chart = name: version: "https://github.com/prometheus-community/helm-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
in
{
  gmp = {
    pod_monitoring =
      { name
      , port
      , matchLabels
      , path ? "/metrics"
      , timeout ? null
      , namespace ? "default"
      , interval ? "30s"
      , metricRelabeling ? [ ]
      }:
      let
        monitor = {
          apiVersion = "monitoring.googleapis.com/v1";
          kind = "PodMonitoring";
          metadata = {
            inherit name namespace;
          };
          spec = {
            endpoints = [
              {
                inherit interval port path;
                ${ifNotEmptyList metricRelabeling "metricRelabeling"} = metricRelabeling;
                ${ifNotNull timeout "timeout"} = timeout;
              }
            ];
            selector = {
              inherit matchLabels;
            };
          };
        };
      in
      toYAMLDoc monitor;
  };
  kube-prometheus-stack = rec {
    defaults = {
      name = "prometheus";
      namespace = "default";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v79-5-0;
      v79-5-0 = _v "79.5.0" "1jvnwqp0jfikyzay4a4jphy6ghnmb0r592r13k6clfb65ab2ykzb"; # 2025-11-11
      v79-4-1 = _v "79.4.1" "13m8dw6fkj7f2izv27bnarrgnbmvbhslpf0bmrlmngin2ibs2f6c"; # 2025-11-08
      v79-4-0 = _v "79.4.0" "0p40z42j9d72pw360bk8n18da4fvfxz6b10zm0dyc4clwiix6qrz"; # 2025-11-07
      v79-3-0 = _v "79.3.0" "0k806p1mznkgi8fda6kqr4qr9hkafp2mmz62m10cswczaqbl47p0"; # 2025-11-07
      v79-2-1 = _v "79.2.1" "1kvxvjpcjg7ydq16p0kpx6a053dk9bxmczx56k46li2j0n8cnwch"; # 2025-11-06
      v79-2-0 = _v "79.2.0" "1rysbfi1x69fvyhvyipfvv5xcfb3f1za4f1jn5sw9cfnc1m6k1cn"; # 2025-11-06
      v79-1-1 = _v "79.1.1" "1j79z3rdi3qbx2m16nmjmp6g9kxqy1vffjbqj4l7g9shwim7idyy"; # 2025-11-02
      v79-1-0 = _v "79.1.0" "0k89l9vnbsh9d2h0mh0m86rb0vzq4qmk834grwbcdcin9kxbv4ph"; # 2025-11-01
      v79-0-1 = _v "79.0.1" "1dy2mr33kk5mxfzb31b39v4gkm7wpdd867xzdfgfq0zb289cmdbd"; # 2025-10-30
      v79-0-0 = _v "79.0.0" "18g80bc5nwy6k4bb18bb3a9k9h7pwg77fjy65ksx2hx291na8c6l"; # 2025-10-27
      v78-5-0 = _v "78.5.0" "0w5ckpqx5d1wfxkaz99x3q7j10cf83n0p8qlxhalhvkjmcrlf21q"; # 2025-10-24
      v78-4-0 = _v "78.4.0" "1mz9042j91p4xhpy257mm0fx7s1379h1khyfzqbcz5w8878j9h51"; # 2025-10-21
      v78-3-2 = _v "78.3.2" "0h9yi451szcm9kbn1hg6v9ywrp4iwx9y8fc28yqg67kw79fh8pfr"; # 2025-10-18
      v78-3-1 = _v "78.3.1" "1qjh35k2zy0vmxyfnminp8196ldp4hi68505asx2h77ryr60hfxq"; # 2025-10-17
      v78-3-0 = _v "78.3.0" "17igvyr5pl2j4ri1r1sj96q41wdp09lihm2w471prq96cc8lzl1w"; # 2025-10-16
      v78-2-1 = _v "78.2.1" "084z95sz9pf57s9pqcvfs4rx6ysh4j6kfzaapq1d0iyy4fkg7y17"; # 2025-10-13
      v78-2-0 = _v "78.2.0" "005830wp5sdc4vms4h6gfcphf75mqdrfy3slkh2h92qa6gfjxy5b"; # 2025-10-12
      v78-1-0 = _v "78.1.0" "1krl0w5ni7xpsz86k5mflb2pyzsigr471lf6a4vkxflgs45fqyq9"; # 2025-10-10
      v78-0-0 = _v "78.0.0" "1xpan30nh7ydvpa69w26vjjd3mbxq490dl1bhmv2mfa227yjdzdk"; # 2025-10-09
      v77-14-0 = _v "77.14.0" "1mc8wwpin7h43nbw069vn73s43h63y8g5j7ib8nd9dcxmvxrdaf1"; # 2025-10-07
      v77-13-0 = _v "77.13.0" "0gbwpsgbrjvcf3n3kkak27gdw1pi0gwjqyfcixz1mlriykm5wyjc"; # 2025-10-03
      v77-12-1 = _v "77.12.1" "0y4gmh7qdcclljy8bfkca4dhik41ckw6s8nc1402my378f317971"; # 2025-10-03
      v77-12-0 = _v "77.12.0" "0narkx00avkrq0hv1il4jn0i7yx8kkvdn645si5g3jfgpkkz4f28"; # 2025-09-26
      v77-11-1 = _v "77.11.1" "151pc45gwgkgindkgw2i79la2hl4spi7lq28i2s6waia47p977mb"; # 2025-09-25
      v77-11-0 = _v "77.11.0" "04abgxx8xqvl8sisqnfbxa9drzqwyfm12qa2pmsyid6hczf8wn26"; # 2025-09-23
      v77-10-0 = _v "77.10.0" "03d7qaq2yyrlaxhkdrh3pg81cwajs52lq0ls1djfg0rqmgni7bcj"; # 2025-09-19
      v77-9-1 = _v "77.9.1" "1rcv0fv818zmk28hgrqn1zzhqhjgmz822wns9jyii8qnma4gy7vr"; # 2025-09-17
      v77-9-0 = _v "77.9.0" "1lwv8qj4bc6l2avnr2dyj14qk24qc94gknbf3a0schvj21ziarw9"; # 2025-09-17
      v77-8-0 = _v "77.8.0" "0ra4payz42c1z7i7snwbd9lh0dql4rwd0f2fi57g4r12yflkyq92"; # 2025-09-16
      v77-7-0 = _v "77.7.0" "1071gw0cxy76qhp59sbjf9sqk55i6f13vy8bkicp98k20yakl1i1"; # 2025-09-16
      v77-6-2 = _v "77.6.2" "0bq6kx7k6ichd6mq5phy5knzyyhj8ashm187jaqy0xqry8wahh2i"; # 2025-09-12
      v77-6-1 = _v "77.6.1" "07yy9l9624q7mqk6slnm9kxhlq2v9798lpgyxyvr3v5z3vdg6c4f"; # 2025-09-11
      v77-6-0 = _v "77.6.0" "05cchr1w2wwgm9wxsii0gw8kavqdkwbbvmj692knxz845k0q6agb"; # 2025-09-09
      v77-5-0 = _v "77.5.0" "1jcfjhn21nwjib9mfljcby7n6gf8vi1rz5r534gs9w4p6l2gq48a"; # 2025-09-03
      v77-4-0 = _v "77.4.0" "1sv22hd0f71242y9mf9gvwypghlm4i3x7kl3qr039rjcca8hmbjn"; # 2025-09-03
      v77-3-0 = _v "77.3.0" "03924vx6z3k1jb7ac39v5cp779z07f1xbm9m414wa91xd0a4jgnb"; # 2025-09-02
      v77-2-1 = _v "77.2.1" "1ckaj3x7z4hx21qmdvh8m5551swd54iyzl8jx5x1wknn8xg70nbz"; # 2025-09-02
      v77-2-0 = _v "77.2.0" "00jlkd08r6v5p41270c3sr0wsv31lj2sy5jrgs5ix4kj1i73dpj0"; # 2025-09-01
      v77-1-3 = _v "77.1.3" "0jsfqbrslc3khykdpyd68kd96sd7brfdnzm5rkkzmigar28h1ipj"; # 2025-09-01
      v77-1-2 = _v "77.1.2" "0rw81knyvh8dx4j0xh4iwxhkhpbx1l2qymiyshpg9747zdypa0wr"; # 2025-09-01
      v77-1-1 = _v "77.1.1" "1592gydd6r3p5nhsxh52b82cwlzs5k3r7aysi71y1wp5347nbzg1"; # 2025-08-31
      v77-1-0 = _v "77.1.0" "0cryq46bfg0k1sglcrnhnqykiasx6mwz5shcsrzkwca6p1h4m659"; # 2025-08-29
      v77-0-2 = _v "77.0.2" "0c1i239zk54ilrz2zq2wc1fr4x7bs5saqm752h28m3kjwq8dkw21"; # 2025-08-26
      v77-0-1 = _v "77.0.1" "1bf3wdpj5m8ajvskmshyw729pj7q763r1hkx3mjzaq915g589rw0"; # 2025-08-25
      v77-0-0 = _v "77.0.0" "1x3k9g0s8mg6g6bsswk6p8rp91g2lw0wdazgcjykwwkqmhw7pdbn"; # 2025-08-23
      v76-5-1 = _v "76.5.1" "0mygin9y3sbgva4dfsddazbm1rpfcg6lq1c710wnhafdvc5f4mqm"; # 2025-08-22
      v76-5-0 = _v "76.5.0" "1byq1scvgldsy5hij58j2z8n8znm8l211ai5r799k55phv0h1k7q"; # 2025-08-22
      v76-4-1 = _v "76.4.1" "0q19apv816ag5r40w0cakdpqjsbp4x2db8nqf2bq1l996s7w1pkh"; # 2025-08-21
      v76-4-0 = _v "76.4.0" "1ckv9wb0khw0b25wcmm5v14km86qg6wla7gawl4y0q238v7bv3gh"; # 2025-08-15
      v76-3-1 = _v "76.3.1" "05019fcxlzq6g0vbl7ns196i39bqh0iqx2rpn5ls1v4b89jjvna7"; # 2025-08-15
      v76-3-0 = _v "76.3.0" "0z1d4ryclg7vrn4b488dkj4p91l81kilcr2i6dc8ic44mfmal0hn"; # 2025-08-12
      v76-2-2 = _v "76.2.2" "1vqy3gh6spsd0ira5229dbrlyb0rsb22kb9i4i0pclz6syxawk2k"; # 2025-08-12
      v76-2-1 = _v "76.2.1" "1w6yjf2z1nimckmgm7215xvdznqssn4fdl5q9pfhlbz8snnhlrvx"; # 2025-08-11
      v76-2-0 = _v "76.2.0" "0vjgi7kdgznivgbp13zvdllnzb0l1l7q0w88b6jhr75x68r06vsq"; # 2025-08-08
      v76-1-0 = _v "76.1.0" "1hfccyb066kfkfkqhz357r2qj5vh3qmn8qlwnwm9gijmk8bnb49g"; # 2025-08-08
      v76-0-0 = _v "76.0.0" "1ylkja2vhq07y9jig2gs341zyfyq6snr92ndqnvdzaxgv5kgxf80"; # 2025-08-08
      v75-18-1 = _v "75.18.1" "1114fz0wk7dknwylq1x010q7cbnj8n5ki244bdw944gskqlnx417"; # 2025-08-07
      v75-18-0 = _v "75.18.0" "0wmyyj6bg64jlalx40qyjshidbp4dd548cky4nfbx8hzsr23ivcm"; # 2025-08-07
      v75-17-1 = _v "75.17.1" "11v9k0ykc76rl1yanr8sfgib76djzf75hb48iihr820w8rvzx2wd"; # 2025-08-06
      v75-17-0 = _v "75.17.0" "00n1nb2sbinzwpb1lpf0ajn1vcy9qmglhwkzbh3fsnlfx8gk5nsx"; # 2025-08-06
      v75-16-1 = _v "75.16.1" "1m31zbghsbx4w1h0zz5c5hxrqhajaapz0nmmv9gdlhzmip20sk34"; # 2025-08-05
      v75-16-0 = _v "75.16.0" "1x5n42zp663cps5618502llvsrr1m69cfbgrqffqrk7l7sqx2qjb"; # 2025-08-05
      v75-15-2 = _v "75.15.2" "19gws6y82q612ya2n46wdyq24yhfdwpxgf3h542apqvy2a5870ap"; # 2025-08-04
      v75-15-1 = _v "75.15.1" "1ffvlggncaz5igiqklmjj8g4h4f2pqwvi17nhq5w7dcgk6gm0liq"; # 2025-07-28
      v75-15-0 = _v "75.15.0" "1cxapxc5xyax73naahwl39118n8dfaf9hiqylagr2yfwk35jwp0s"; # 2025-07-25
      v75-14-0 = _v "75.14.0" "04sgfz0w9h4mbf33yik0ph3kyf3kavh2vn0d3105hikljf2cbx6z"; # 2025-07-25
      v75-13-0 = _v "75.13.0" "004w78ivjiv1alc0zyqp31fa7x1a8g7bjsisqfsha1rlgmihrwld"; # 2025-07-22
      v75-2-1 = _v "75.2.1" "0prnycnj040s21fya3qh838irg6l36jk32mh88lcsy5467djj2j7"; # 2025-06-17
      v74-2-2 = _v "74.2.2" "1wim07pq0ry3h7inip96864bjirzkbqrjklsd48p35nk7msrd8r7"; # 2025-06-16
      v74-0-0 = _v "74.0.0" "03256gfzj906dplpywdc3slczr017lpw91xarkzwla0zpbld840l"; # 2025-06-12
      v73-2-3 = _v "73.2.3" "0xs2h5zs902y1xkz7z8zvrc3cqwj5jwcd3lcfd3bf5370smfc8pr"; # 2025-06-12
      v73-0-0 = _v "73.0.0" "13jwi7y8fralgzyb9j8f4fb5vl9z31g8g61pa7km0bqvsr1z65s3"; # 2025-06-03
      v72-9-1 = _v "72.9.1" "1wvcqhbjsb25n2kapy7hia2w6pgk2jj6gnp8w4aapnmmx2mnbk8q"; # 2025-06-02
      v72-4-0 = _v "72.4.0" "1d9n2jrkb10mw9plfn6vs4imd56jqhlr7fprfkrvb8xhsa87kk12"; # 2025-05-15
      v72-3-1 = _v "72.3.1" "04v27ycq9gpsvgglyjd8j8jgmh4fav9s54zizyz23gpipxzangma"; # 2025-05-13
      v71-2-0 = _v "71.2.0" "13va79agsa1jgw29zxsw8x8gl0jzyf0hb3m2cgi687yp8zrabh11"; # 2025-05-02
      v70-10-0 = _v "70.10.0" "1fhnbrsc93ph692xa9nn1afcryb6s3zkv6df1xs4p956m17wv3fz"; # 2025-04-27
      v69-7-4 = _v "69.7.4" "1pm0mvk5nb86v2kghdbxfj0bm9crh85dbrk9x4cyiycc4bahb6pk"; # 2025-03-06
      v68-5-0 = _v "68.5.0" "1l8ljjqdaks72f41dp2mkczgk8cdi5mlks8349cmra71pg8hndxa"; # 2025-02-06
      v67-11-0 = _v "67.11.0" "1rvvlmq58wvy517x8fdp5irbi8cldv27xhqmzp554c7dfcgznfbv"; # 2025-01-13
      v66-7-1 = _v "66.7.1" "0ihwsb1rm1zh11q3h813yigml2nvwkbwsxcp2hr8lmwf89nqd4wm"; # 2024-12-15
      v61-3-2 = _v "61.3.2" "1dcgfs63hfc83bjqwaqgrc9b7ifqmcs2ky4350razrc6klkgwsah"; # 2024-07-17
      v60-5-0 = _v "60.5.0" "1qdlbk5hg9a6qfw82h0wwc8akwflanh4lpzlncvy2i0ln35v73cl"; # 2024-06-28
      v59-1-0 = _v "59.1.0" "0v8pw8361zbj8c67cvhk3z2303dsmb4b10fqz4asc0xgql5fjmp0"; # 2024-05-31
      v58-7-2 = _v "58.7.2" "0wj32vygf98l0hpwjarhyl5krwbiapvb487682mqaqsbh1iqb3x1"; # 2024-05-24
      v58-0-0 = _v "58.0.0" "0kr65dkhk8728sdg1lm562zqsknpnw6wfq3jdg150d8yzlz3cdrg"; # 2024-04-06
      v57-2-1 = _v "57.2.1" "1p87qngiab98n6l59432harkmg53c9vk1wl7hmfllp7wphcflsx8"; # 2024-04-06
      v56-21-4 = _v "56.21.4" "16ihd84isg09clhyyjf5r7h3s9pcisl8201dya6p0hl6gd15935l"; # 2024-03-08
      v56-2-0 = _v "56.2.0" "0halhmdxyrn5drimyx1hp9sgxyh1qcz9gsb5vn3jmbsx0grv94yn";
      v56-1-0 = _v "56.1.0" "18vhd3455pq894gnanczkns6mw18byk9hhvyn8iz1ss17wyqcaif";
      v55-11-0 = _v "55.11.0" "06l4bn25illfwm2k0jlibxz2ndqbl09xg7mim2ym0rim0m0rljfl";
      v54-2-2 = _v "54.2.2" "051mdacf2z442qqmj4gp62h8xx0wjm4k5jh8sxnd8ar5nr24jyhs";
      v53-0-0 = _v "53.0.0" "0gl5bd5dbwhxg0zi1mygdgg0j080vk346dipi4sc8gq0b583vy8s";
      v52-1-0 = _v "52.1.0" "0ahd8cw7kx7hgnffw6jiyhdvpg5iwn2k8qq1y01dfk7rbbcxnpsr";
      v51-10-0 = _v "51.10.0" "1yw9bkgiws4d34fbavnlhk87srfvvpv1dajyk8v7npai237415dq";
      v50-3-1 = _v "50.3.1" "12dy66syz0417z75kwmzciv4s4g93fd03n5jrzzyridzbr3mdiv7";
      v49-2-0 = _v "49.2.0" "0wvwlfp07827z1zxxnaizvcgrla9paz4f127dfgx86jlc07s9xci";
      v48-6-0 = _v "48.6.0" "0xsfvnl9vfh7skjlim0xgw6dxfp393lr0001sv1icmpfq8fkvlrr";
      v48-4-0 = _v "48.4.0" "0wvl3n2ds3jgfb0cbwp1dq59xh7zyqh7mvhw6ndiyzsyssipg573";
    };
    chart_url = prom_chart "kube-prometheus-stack";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
  adapter = rec {
    defaults = {
      name = "prometheus-adapter";
      namespace = "default";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v4-11-0;
      v4-11-0 = _v "4.11.0" "1g69cgmbgqsnabg75jvp2d8vzi05x6k5q1aal1pvqriy0mjy20lg"; # 2024-08-10
    };
    chart_url = prom_chart "prometheus-adapter";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
  pushgateway = rec {
    defaults = {
      name = "prometheus-pushgateway";
      namespace = "default";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v2-13-0;
      v2-13-0 = _v "2.13.0" "0p8jc1xalkmsm3y666nrzm0srrlkf1zyr2cmqq448mf7f6zf68vr"; # 2024-06-05
    };
    chart_url = prom_chart "prometheus-pushgateway";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
  exporters = {
    cloudwatch = rec {
      defaults = {
        name = "prometheus-cloudwatch-exporter";
        namespace = "default";
      };
      version = rec {
        _v = hex.k8s._.version chart;
        latest = v0-25-3;
        v0-25-3 = _v "0.25.3" "0pxaj0ayp2yh9cs554r41y5zya4a9f7nx81xr6irki11kj6ys9na"; # 2023-12-16
      };
      chart_url = prom_chart "prometheus-cloudwatch-exporter";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
    elasticsearch = rec {
      defaults = {
        name = "prometheus-elasticsearch-exporter";
        namespace = "default";
        version = "5.4.0";
        sha256 = "0rbrq4k0rqvpxx4xhb7sf6m4jdz2giwv6kfmsizbk7fjw05yiilx";
      };
      version = rec {
        _v = hex.k8s._.version chart;
        latest = v5-4-0;
        v5-4-0 = _v "5.4.0" "0rbrq4k0rqvpxx4xhb7sf6m4jdz2giwv6kfmsizbk7fjw05yiilx"; # 2023-12-25
      };
      chart_url = prom_chart "prometheus-elasticsearch-exporter";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
    mongodb = rec {
      defaults = {
        name = "prometheus-mongodb-exporter";
        namespace = "default";
        version = "3.5.0";
        sha256 = "08sg78nqld5h7ynfznf3zn185s9nxsj278xh5p1waw6hxk8993gk";
      };
      version = rec {
        _v = hex.k8s._.version chart;
        latest = v3-5-0;
        v3-5-0 = _v "3.5.0" "08sg78nqld5h7ynfznf3zn185s9nxsj278xh5p1waw6hxk8993gk"; # 2023-12-14
      };
      chart_url = prom_chart "prometheus-mongodb-exporter";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
    mysql = rec {
      defaults = {
        name = "prometheus-mysql-exporter";
        namespace = "default";
        version = "2.4.0";
        sha256 = "0ksm6hxwka2wiw7lzngs27xffm4i2sp9h0i2xqhbviwkd9pppwd4";
      };
      version = rec {
        _v = hex.k8s._.version chart;
        latest = v2-4-0;
        v2-4-0 = _v "2.4.0" "0ksm6hxwka2wiw7lzngs27xffm4i2sp9h0i2xqhbviwkd9pppwd4"; # 2024-01-10
      };
      chart_url = prom_chart "prometheus-mysql-exporter";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
    postgres = rec {
      defaults = {
        name = "prometheus-postgres-exporter";
        namespace = "default";
        version = "5.3.0";
        sha256 = "0zimga6ya5f2cf736yc0svmd8bs7v7nhrahsm56xzj26r89cwrh9";
      };
      version = rec {
        _v = hex.k8s._.version chart;
        latest = v5-3-0;
        v5-3-0 = _v "5.3.0" "0zimga6ya5f2cf736yc0svmd8bs7v7nhrahsm56xzj26r89cwrh9";
      };
      chart_url = prom_chart "prometheus-postgres-exporter";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
    redis = rec {
      defaults = {
        name = "prometheus-redis-exporter";
        namespace = "default";
        version = "6.1.1";
        sha256 = "0im2gkiijz0ggsnw39my7j0w1f8m7msd5hkr2930i2p2cn5mmp8j";
      };
      version = rec {
        _v = hex.k8s._.version chart;
        latest = v6-1-1;
        v6-1-1 = _v "6.1.1" "0im2gkiijz0ggsnw39my7j0w1f8m7msd5hkr2930i2p2cn5mmp8j"; # 2024-01-30
      };
      chart_url = prom_chart "prometheus-redis-exporter";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
  };
}
