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
      latest = v75-13-0;
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
