# [postgres-operator](https://github.com/zalando/postgres-operator) creates and manages PostgreSQL clusters running in Kubernetes
{ hex, ... }:
let
  repo_url = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator";
  postgres = {
    operator = rec {
      defaults = {
        name = "postgres-operator";
        namespace = "default";
      };
      version = rec {
        _v = hex.k8s._.version chart;
        latest = v1-14-0;
        v1-14-0 = _v "1.14.0" "1h1n7aasn8ivahx1hb9vm9vpvkw7anx717b12yvrpxcras1d27al"; # 2024-12-23
        v1-12-2 = _v "1.12.2" "19fxzl2r3aj53cql7w01p6pvq6k19lkrjr8yq1jvz8896vhnrcnw"; # 2024-06-14
        v1-11-0 = _v "1.11.0" "0ypjzvikjq085yvh7m6c74x9dk8zark0gmdj2f34lph9hm78al1x"; # 2024-03-27
        v1-10-1 = _v "1.10.1" "04wpirx90j7jvnkv1pr99pyhn3jhp3mcp8529qhkfmpjjl76w0kk";
        v1-10-0 = _v "1.10.0" "1hjv747i0awgcgq095gjilk5fmy8ibcc86p0mlz8imygfd6g792z";
      };
      chart_url = version: "${repo_url}/${defaults.name}-${version}.tgz";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
    ui = rec {
      defaults = {
        name = "postgres-operator-ui";
        namespace = "default";
      };
      version = rec {
        _v = hex.k8s._.version chart;
        latest = v1-14-0;
        v1-14-0 = _v "1.14.0" "08jzxyny9hbnc4dyabv6ssbz5vf6rsjja1r46rlyfxs529532wf8"; # 2024-12-23
        v1-12-2 = _v "1.12.2" "1sxm4p8phay65gxxrqdkhfb0f05vh8jrs4w8jmw0b1f5di4r6jsa"; # 2024-06-14
        v1-11-0 = _v "1.11.0" "035ri6b4mjvdlhrwl8fpyw173bf9ny9qla5fvql9c4yj7gw4j2q2"; # 2024-03-14
        v1-10-1 = _v "1.10.1" "04sfk6habw9w1laci5rynzhxqvgpkxmadcxzabk98v03dds9gjl8";
        v1-10-0 = _v "1.10.0" "18x16v75rzl7d2rrl455ilr3n8sz83n0n5vwkpl9sz7jnva66g4f";
      };
      chart_url = version: "${repo_url}-ui/${defaults.name}-${version}.tgz";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };

    # an example function for creating dbs with this operator - not fully complete!
    db =
      { name
      , user ? "user"
      , dbName ? name
      , version ? "16"
      , namespace ? "default"
      , team ? "team"
      , cpuRequest ? "500m"
      , cpuLimit ? "1000m"
      , memoryRequest ? "2Gi"
      , memoryLimit ? "4Gi"
      , storageClass ? "local-path"  # change this if not on k3s!
      , size ? "64Gi"
      , parameters ? { }
      , logicalBackups ? false
      , allowedSourceRanges ? null
      }:
      let
        spec = {
          apiVersion = "acid.zalan.do/v1";
          kind = "postgresql";
          metadata = {
            inherit name namespace;
            labels = { inherit team; };
          };
          spec = {
            ${if allowedSourceRanges != null then "allowedSourceRanges" else null} = allowedSourceRanges;
            databases."${dbName}" = user;
            enableLogicalBackup = logicalBackups;
            numberOfInstances = 1;
            postgresql = {
              inherit version;
              ${if logicalBackups != { } then "parameters" else ""} = parameters;
            };
            resources = {
              limits = {
                cpu = cpuLimit;
                memory = memoryLimit;
              };
              requests = {
                cpu = cpuRequest;
                memory = memoryRequest;
              };
            };
            teamId = team;
            users = {
              "${user}" = [ "superuser" "createdb" ];
            };
            volume = {
              inherit size storageClass;
            };
          };
        };
      in
      hex.toYAMLDoc spec;
  };
in
postgres
