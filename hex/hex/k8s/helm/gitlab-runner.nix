# This module contains the helm chart for the [GitLab Kubernetes Executor](https://docs.gitlab.com/runner/executors/kubernetes.html).
{ hex, ... }:
let
  gitlab-runner = rec {
    defaults = {
      name = "gitlab-runner";
      namespace = "gitlab";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-80-0;
      v0-80-0 = _v "0.80.0" "0mlzhf757wplskhyxqqcwkqfyhm8x6l4ca3rfwa9mx38ckr4j2zb"; # 2025-08-22
      v0-79-1 = _v "0.79.1" "14yvp8dgcziz7inl11sky00j0sp5pak5i0dx2lpsz8kyi01sv2h4"; # 2025-07-28
      v0-78-3 = _v "0.78.3" "0qd20aj0rky91szdc22n1b2q40br8r8gnxnmxwnwywja8iblrghx"; # 2025-07-29
      v0-77-5 = _v "0.77.5" "1vdl08cixm8pb0kq5dv4w2bf2b4sjj6hjc1yqm960y3pid5kzdb0"; # 2025-07-29
      v0-76-3 = _v "0.76.3" "05z5df4r5g4vdr4lan2nm54lrg35rbjbg3gkzvrm4bsqwi01yd3s"; # 2025-06-11
      v0-76-0 = _v "0.76.0" "1sl8z89s89g1gars1xw4cda1rwhsb3x2qq02g8x1gyqk5mi0vcz0"; # 2025-04-17
      v0-75-1 = _v "0.75.1" "0p51a87n02qibmjjin8lafmrv6j5a54pd922nr2ls6x8jpy98cmc"; # 2025-03-27
      v0-75-0 = _v "0.75.0" "1mq2fycdz03gskdg1my4iimq4ad7jd3png7zsd3vhx2zaa7csixl"; # 2025-03-19
      v0-74-2 = _v "0.74.2" "005ga7bnj1g5ab06ghi7lxymzdcfqi84r59fc4yj248c86wiylbc"; # 2025-03-20
      v0-74-0 = _v "0.74.0" "0ckv286l66rn7pa4vshnjzpa035rhkiash0ipab23hc4a1adwr5q"; # 2025-02-20
      v0-73-3 = _v "0.73.3" "1qpvvg4fp534yfjj0wwdzgn86p64a8z52my0qmmkvhpsvrjrd8vp"; # 2025-01-23
      v0-72-1 = _v "0.72.1" "1df63dfvwj97yzn6fkc2yv3cm4wx5fipn250ayrnv9gwzhhnx8vh"; # 2025-01-18
      v0-71-0 = _v "0.71.0" "18gd8kjjg5imsw1bqmycdiz5ks8q4ibg5pv7s96s5kx805084xx9"; # 2024-11-20
      v0-70-5 = _v "0.70.5" "061xq1jvd4g1iv03nx5l3ig31iwdd2yja6lyck0cd4z9fafd4l2z"; # 2024-12-20
      v0-69-2 = _v "0.69.2" "0f6xshj3gszvjpvngln7m46vzrayv6a1fwr85cmgmjqln4xabhkd"; # 2024-10-23
      v0-68-0 = _v "0.68.0" "1al9sfamj5wi4zwhmylvdyz6vvx36aapzkgzl7k1wijj7y8y49rv"; # 2024-08-15
      v0-67-1 = _v "0.67.1" "0ygszspsvx7wd3p1r5461s0dm5p9dx0d66ln1bw0jd8d4film8vd"; # 2024-07-26
      v0-66-0 = _v "0.66.0" "08fk6bz37sy8qdaqxbik4vpv0dwbrxggg6z1mp8mbs89zl206pnb"; # 2024-06-20
      v0-65-0 = _v "0.65.0" "1rpfnbx35ysvip2fr89hm4gnk4ficvpkz60rf2v56sq2dhchvl2f"; # 2024-05-23
      v0-64-1 = _v "0.64.1" "1xyxz4v3700kl14cjb37wm7wvcwdyk8qn2w5fisqz16x76hms6mh"; # 2024-05-03
      v0-63-0 = _v "0.63.0" "1nk77r2dcg3l1l2fpyp4dh79dvfmljfpch7n2v50ba1pmxca6qxj"; # 2024-03-22
      v0-62-0 = _v "0.62.0" "1h8zj211a6z1fmrs8ikf232fswyrf4x8zk90kdq84yga62brvbvr"; # 2024-02-15
      v0-61-3 = _v "0.61.3" "1qvv5zazaa7039jjkbh4rbi36dnx0s6zxvs73b211bz3jb6wrj5v"; # 2024-02-15
      v0-61-0 = _v "0.61.0" "0hc4b1v350hlnr0filwccza6bfyx0grabq8ldfgnc6chbl4m323d"; # 2024-01-19
      v0-60-1 = _v "0.60.1" "0r224arp4zi76d7sbybg9rdnwzwkl6ayq8iwb3v2zk8w83p0y33y"; # 2024-01-19
      v0-60-0 = _v "0.60.0" "1k0gdg2mvm98s8msrsnr0aqsblhigbr7y6fg263yd6mmg8yzxlcp"; # 2023-12-21
      v0-59-3 = _v "0.59.3" "11i6p6bp2ysxyv6v22lv7z8d6nc8nlibvbvvrqxnivrp7wjl4yah"; # 2023-12-21
    };
    chart_url = version: "https://gitlab-charts.s3.amazonaws.com/gitlab-runner-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
gitlab-runner
