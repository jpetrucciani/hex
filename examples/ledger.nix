# Render only: nix run path:.#hex -- --render -t examples/ledger.nix
# A small stateful stack: Postgres, a migration Job, and a background worker, all locked down.
{ hex, ... }:
let
  inherit (hex.k8s) jobs services;
  inherit (services) configs policies volumes;

  namespace = "ledger";
  partOf = { "app.kubernetes.io/part-of" = "ledger"; };
  image = "postgres:17-alpine";
  postgresUser = 70; # the postgres user in the alpine image

  # demo credentials; use an existing Secret or an operator outside of examples
  credentials = configs.secret {
    name = "ledger-db";
    stringData = {
      PGHOST = "ledger-db-headless";
      PGDATABASE = "ledger";
      PGUSER = "ledger";
      PGPASSWORD = "ledger-demo-password";
    };
  };

  migrations = configs.configMap {
    name = "ledger-migrations";
    data."001_entries.sql" = ''
      CREATE TABLE IF NOT EXISTS entries (
        id bigserial PRIMARY KEY,
        created_at timestamptz NOT NULL DEFAULT now()
      );
    '';
  };

  # the worker owns the migrations ConfigMap, so the migration Job inherits its env, volumes, and config hash
  worker = {
    name = "ledger-worker";
    inherit namespace image;
    labels = { app = "ledger-worker"; } // partOf;
    replicas = 1;
    autoscale = false;
    roleBinding = false;
    configs = [ migrations ];
    security = services.security.restricted { runAsUser = postgresUser; };
    envFrom = [{ secretRef.name = credentials.metadata.name; }];
    volumes = [
      (volumes.configMap { name = "migrations"; mountPath = "/migrations"; configMapName = migrations.metadata.name; })
    ];
    command = [ "/bin/sh" "-ec" ];
    args = [ "while true; do psql -c 'INSERT INTO entries DEFAULT VALUES'; sleep 30; done" ];
    cpuRequest = "50m";
    memoryRequest = "64Mi";
    egressPolicy = [
      (policies.egress.dns { })
      (policies.egress.toLabels { labels = { app = "ledger-db"; }; ports = [ 5432 ]; })
    ];
  };
in
''
  ${hex.toYAMLDoc { apiVersion = "v1"; kind = "Namespace"; metadata.name = namespace; }}
  ${services.stateful.build {
    name = "ledger-db";
    inherit namespace image;
    labels = { app = "ledger-db"; } // partOf;
    configs = [ credentials ];
    ports = [ (services.ports.tcp { name = "postgres"; port = 5432; }) ];
    claims = [
      (services.claims.build { name = "data"; mountPath = "/var/lib/postgresql/data"; storage = "1Gi"; })
    ];
    volumes = [
      (volumes.emptyDir { name = "run"; mountPath = "/var/run/postgresql"; })
      (volumes.emptyDir { name = "tmp"; mountPath = "/tmp"; })
    ];
    security = services.security.restricted { runAsUser = postgresUser; fsGroup = postgresUser; };
    envFrom = [{ secretRef.name = credentials.metadata.name; }];
    envAttrs = {
      POSTGRES_DB = "ledger";
      PGDATA = "/var/lib/postgresql/data/pgdata";
    };
    env = [
      { name = "POSTGRES_USER"; valueFrom.secretKeyRef = { inherit (credentials.metadata) name; key = "PGUSER"; }; }
      { name = "POSTGRES_PASSWORD"; valueFrom.secretKeyRef = { inherit (credentials.metadata) name; key = "PGPASSWORD"; }; }
    ];
    readinessProbe = services.probes.exec { command = [ "pg_isready" "-h" "127.0.0.1" ]; periodSeconds = 5; };
    cpuRequest = "100m";
    memoryRequest = "256Mi";
    ingressPolicy = [
      (policies.ingress.fromLabels { labels = partOf; ports = [ 5432 ]; })
    ];
    egressPolicy = [ ];
  }}
  ${jobs.fromService worker {
    name = "ledger-migrate";
    labels = { app = "ledger-migrate"; } // partOf;
    command = [ "/bin/sh" "-ec" ];
    args = [ "until pg_isready; do sleep 2; done; for f in /migrations/*.sql; do psql -v ON_ERROR_STOP=1 -f \"$f\"; done" ];
    activeDeadlineSeconds = 600;
  }}
  ${services.worker worker}
''
