# [sentry](https://github.com/getsentry/sentry) is a Developer-first error tracking and performance monitoring platform.
{ hex, ... }:
let
  sentry = rec {
    defaults = {
      name = "sentry";
      namespace = "sentry";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v26-15-0;
      v26-15-0 = _v "26.15.0" "0x5irmqsl9yp7c6qxqwwm90m96ymhgqvs7g0dpcki67v6kcbd1mh"; # 2025-03-06
      v23-11-0 = _v "23.11.0" "1hvdavc8g3iwx3p424f8z4dlvksf2zaq7afb2wdvr2sa297l0szn"; # 2024-06-24
      v23-1-0 = _v "23.1.0" "0kk1h74vd6zqf39fy1p16glql85p0d7b3xr6p502rk1rvy8wzfd5"; # 2024-05-23
      v22-5-1 = _v "22.5.1" "1hkr8d2n5znfx4ddazrpfx3jhasq4n7i1yk7d4593ryiadp9260b"; # 2024-05-23
      v21-6-3 = _v "21.6.3" "11hk7vs9v8hvr0y2kk2gl0c8pjmkvssl7s2499d7291gl3kvqmj7"; # 2024-05-23
      v21-6-0 = _v "21.6.0" "0cgzffbhjy4nrnbc5j0ar49x75lbczlag48crsil6aplmg1h1i0f"; # 2024-03-15
      v21-5-0 = _v "21.5.0" "19gj2sz1nvvf5m68lgv0x4148zvn1wz91cfnzzrd2kzkxgjc0rcp";
      v21-0-0 = _v "21.0.0" "0csjqlhf2x0vd9bxdv2kwji03bx2z27g3vnyhds9m0h4fmiclsbw"; # 2024-01-17
      v20-12-2 = _v "20.12.2" "145r75rlxwk4xlhxdlf8lidmi9z8ljxrdi7mqjp72qgm35qc26n1"; # 2024-01-17
      v20-12-1 = _v "20.12.1" "1jvhi18yp88lvqg3ppwknhjv1gwda3kn55pzibf1jlg09ygk412z";
      v20-11-0 = _v "20.11.0" "1hdj512c69ja4rsff44c93zq9imlij3ky7w2k0g3qycljghas4zb";
      v20-10-1 = _v "20.10.1" "11l4fqg5l38n5kp68xj1ls3153m3bdzjks9j3w29p1j7ygn80vz3";
      v20-9-3 = _v "20.9.3" "0k2mf96kpjrfnjwqz21nal6pgx2bfv8ma5nik42ma0kbwisdb4yj";
      v20-8-2 = _v "20.8.2" "1x21a1p3ny5v2v7dvxy3jgha6mcmv0kfh9qwc0yiwjl97j1w4qnb";
      v20-4-0 = _v "20.4.0" "0r3lz1fqb7x6bcgnja8mhk7i0f3747a1g9ymx9ly2j05zzyp81jf";
      v20-3-2 = _v "20.3.2" "1xwg8s5zxm24x1rspjgk9zwgxv8kkkywf2hl6qj149fvxn0k758d";
      v20-3-0 = _v "20.3.0" "0f09rlq6m98n9jjlk42rrkhyf39jh4ppz5rmx2ngx5nipkvrjkj9";
    };
    chart_url = version: "https://sentry-kubernetes.github.io/charts/sentry-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
sentry
