# This module contains a [semaphore](https://github.com/semaphoreui/semaphore) chart
{ hex, ... }:
let
  semaphore = rec {
    defaults = {
      name = "semaphore";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v16-0-11;
      v16-0-11 = _v "16.0.11" "05kp2jm1lx8brplnb2gvi2m9qyrwlsf3la7hrjpqpzzi2yyxpkn9"; # 2025-12-17
      v16-0-10 = _v "16.0.10" "0mj0sdz7kvzi0kixf1gzkpigb6ych6l1s25nym4acj2k1pmvw7lq"; # 2025-11-16
      v16-0-9 = _v "16.0.9" "1pwvir5r3xnhbfzlz0s8d5a24v4wwgrip4hgzg916lybjvwz9w08"; # 2025-11-05
      v16-0-8 = _v "16.0.8" "0jmwjvnhp55j5gbhidkais53lm0ykxprsf8am6as23xchkvn4a9y"; # 2025-11-05
      v16-0-6 = _v "16.0.6" "0s7f45p9xcz4akzjcq4fzibh3wif24nbqaskqjxh24pickicjmbc"; # 2025-10-28
      v16-0-5 = _v "16.0.5" "10vn6n43i4qx2z2acxdan6crcnzi0jdvzvbia15h3k2dqa4z9822"; # 2025-10-10
      v16-0-4 = _v "16.0.4" "0g66cljpv6qzn8xmh4m14alb3g7qlysd1g7jrsbfgh1i8lby7pmr"; # 2025-09-17
      v16-0-3 = _v "16.0.3" "1bjg0lgx6l3rxrs08k5h9ws28az4iqc0wlysyzkk3s85fp8l6r35"; # 2025-09-16
      v16-0-2 = _v "16.0.2" "0l3k95a1im2v5lnasq25n37y5h2b5vzyp2yvzyw7sqn0gikqai39"; # 2025-07-24
      v16-0-1 = _v "16.0.1" "13ll37ipqmh35qg9346j9zsc1lbf8cv4xmih4cy51zykywc07dnx"; # 2025-07-21
      v16-0-0 = _v "16.0.0" "0hc8mbb3cnk1yqr5hbyzkdniv35barkpxh1d9m64pb5vb125af6y"; # 2025-06-14
      v15-1-6 = _v "15.1.6" "1nyy5iq5wj8b39v1xzxy25by38wsw3zsp65wb964vdn83b8bps9a"; # 2025-05-06
    };
    chart_url = version: "https://github.com/semaphoreui/charts/releases/download/semaphore-${version}/semaphore-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
semaphore
