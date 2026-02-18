{ _compat ? import ./flake-compat.nix
, pkgs ? import _compat.inputs.nixpkgs { overlays = [ pog.overlay ]; }  # TODO: document this, or fix it so we don't have to rely on the end user to provide pog in their pkgs
, pog ? import _compat.inputs.pog { }
, system ? pkgs.system
}:
let
  params = { inherit system pkgs; };
  hex = import ./hex params;
  docsIndex = import ./hex/hex/k8s/docs-index.nix { inherit pkgs; };
  deps = import ./hex/hex/deps.nix { inherit pkgs; };
  test =
    let
      heval = "${hex.hex}/bin/hex -r -e";
      mktemp = "${pkgs.coreutils}/bin/mktemp --suffix=.yaml";
      tests = let num_docs = num: ''[ "$num_docs" -ne ${toString num} ] && echo "[$name] not the correct number of docs! expected ${toString num}, but got $num_docs" && exit 1''; in [
        { name = "cronjob"; spec = ''hex.k8s.cron.build {name = "test"; extra={spec.timeZone ="America/Chicago";};}''; check = num_docs 1; }
        { name = "litellm"; spec = "hex.k8s.svc.litellm {}"; check = num_docs 6; }
        { name = "lobe-chat"; spec = "hex.k8s.svc.lobe-chat {}"; check = num_docs 5; }
        { name = "metabase"; spec = ''hex.k8s.svc.metabase {domain = "meme.com";}''; check = num_docs 5; }
        { name = "external-secrets"; spec = "hex.k8s.external-secrets.version.v0-17-0 {}"; check = num_docs 39; }
        { name = "external-secrets"; spec = "hex.k8s.external-secrets.version.v0-18-0 {}"; check = num_docs 40; }
        { name = "mimir"; spec = "hex.k8s.grafana.mimir.version.latest {}"; check = num_docs 81; }
        { name = "tempo"; spec = "hex.k8s.grafana.tempo.version.latest {}"; check = num_docs 20; }
        { name = "semaphore"; spec = "hex.k8s.semaphore.version.latest {}"; check = num_docs 9; }
        { name = "netbox"; spec = "hex.k8s.netbox.version.latest {}"; check = num_docs 33; }
        {
          name = "loki";
          spec = ''hex.k8s.grafana.loki.version.latest {
            valuesAttrs.loki = {
              schemaConfig = { configs = [ { from = "2024-04-01"; index = { period = "24h"; prefix = "loki_index_"; }; object_store = "s3"; schema = "v13"; store = "tsdb"; } ]; };
              storage = {type="s3"; bucketNames=let b = "bucket"; in {admin=b;chunks=b;ruler=b;};};
            };
          }'';
          check = num_docs 30;
        }
        { name = "coroot-node-agent"; spec = ''hex.k8s.coroot.node-agent.version.latest {}''; check = num_docs 1; }
        { name = "open-webui"; spec = "hex.k8s.open-webui.version.latest {}"; check = num_docs 14; }
        { name = "cert-manager"; spec = "hex.k8s.cert-manager.version.latest {}"; check = num_docs 46; }
        { name = "redpanda"; spec = "hex.k8s.redpanda.version.latest {}"; check = num_docs 9; }
        { name = "questdb"; spec = "hex.k8s.questdb.version.latest {}"; check = num_docs 5; }
        { name = "questdb"; spec = "hex.k8s.questdb.version.v1-0-17 {}"; check = num_docs 5; }
        { name = "jupyterhub"; spec = "hex.k8s.jupyterhub.version.v4-3-1 {}"; check = num_docs 30; }
        { name = "prefect-server"; spec = "hex.k8s.prefect.server.version.latest {}"; check = num_docs 8; }
        { name = "prefect-worker"; spec = ''hex.k8s.prefect.worker.version.latest { valuesAttrs.worker = { apiConfig = "selfHostedServer"; config.workPool = "test"; selfHostedServerApiConfig.apiUrl="127.0.0.1"; }; }''; check = num_docs 4; }
        { name = "trino"; spec = ''hex.k8s.trino.trino.version.latest {}''; check = num_docs 10; }
        { name = "trino-gateway"; spec = ''hex.k8s.trino.gateway.version.latest {}''; check = num_docs 6; }
        { name = "nats"; spec = ''hex.k8s.nats.version.latest {}''; check = num_docs 8; }
        { name = "dask"; spec = ''hex.k8s.dask.kubernetes-operator.version.latest {}''; check = num_docs 8; }
        { name = "prometheus-adapter"; spec = ''hex.k8s.prometheus.adapter.version.latest {}''; check = num_docs 11; }
        { name = "prometheus-pushgateway"; spec = ''hex.k8s.prometheus.pushgateway.version.latest {}''; check = num_docs 3; }
        { name = "prometheus-exporters-cloudwatch"; spec = ''hex.k8s.prometheus.exporters.cloudwatch.version.latest {}''; check = num_docs 7; }
        { name = "prometheus-exporters-elasticsearch"; spec = ''hex.k8s.prometheus.exporters.elasticsearch.version.latest {}''; check = num_docs 2; }
        { name = "prometheus-exporters-mongodb"; spec = ''hex.k8s.prometheus.exporters.mongodb.version.latest {}''; check = num_docs 5; }
        { name = "prometheus-exporters-mysql"; spec = ''hex.k8s.prometheus.exporters.mysql.version.latest {}''; check = num_docs 3; }
        { name = "prometheus-exporters-nats"; spec = ''hex.k8s.prometheus.exporters.nats.version.latest {}''; check = num_docs 3; }
        { name = "prometheus-exporters-postgres"; spec = ''hex.k8s.prometheus.exporters.postgres.version.latest {}''; check = num_docs 6; }
        { name = "prometheus-exporters-redis"; spec = ''hex.k8s.prometheus.exporters.redis.version.latest {}''; check = num_docs 5; }
      ];
      test_case = x:
        let
          log = text: ''echo "[${x.name}] ${text}"'';
        in
        ''
          name=${x.name}
          ${log "test"}
          rendered="$(${mktemp})"
          # shellcheck disable=SC2064
          trap "rm -f $rendered" EXIT
          ${heval} '${x.spec}' >$rendered
          exit_code=$?
          ${log "rendered to $rendered"}
          num_docs="$(${pkgs.yq-go}/bin/yq e 'document_index + 1' $rendered | ${pkgs.coreutils}/bin/tail -n 1)"
          ${log "exit code: $exit_code"}
          ${log "num docs: $num_docs"}
          ${x.check or ""}
          rm "$rendered"
          exit $exit_code
        '';
      test_scripts = map (x: pkgs.writeShellScript "test-${x.name}" (test_case x)) tests;
    in
    pkgs.writers.writeBashBin "test" ''
      ${pkgs.parallel}/bin/parallel \
        --will-cite \
        --keep-order \
        --line-buffer \
        --color \
        "$@" \
        ::: ${pkgs.lib.concatStringsSep " " test_scripts}
    '';
in
hex // { inherit deps docsIndex test; }
