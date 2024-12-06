# This module contains k8s helpers for AWS related functionality
{ hex, services, ... }:
let
  inherit (hex) toYAMLDoc concatStringsSep;
  inherit (services) components;
  defaults = {
    region = "us-east-2";
    image = "ghcr.io/jpetrucciani/k8s-aws";
  };
in
{
  aws_auth = { account_id, node_role_names ? [ ], admins ? [ ] }:
    let
      admin_entry = user: ''
        - userarn: arn:aws:iam::${account_id}:user/${user}
          username: ${user}
          groups:
            - system:masters
      '';
      node_role_entry = node_role: ''
        - groups:
            - system:bootstrappers
            - system:nodes
          rolearn: arn:aws:iam::${account_id}:role/${node_role}
          username: system:node:{{EC2PrivateDNSName}}
      '';
      auth_map = {
        apiVersion = "v1";
        data = {
          mapRoles = concatStringsSep "\n" (map node_role_entry node_role_names);
          mapUsers = concatStringsSep "\n" (map admin_entry admins);
        };
        kind = "ConfigMap";
        metadata = {
          name = "aws-auth";
          namespace = "kube-system";
        };
      };
    in
    toYAMLDoc auth_map;
  ecr_cron =
    { account_id
    , name ? "ecr-login"
    , namespace ? "default"
    , region ? defaults.region
    , image ? defaults.image
    , image_tag ? "latest"
    , aws_secret ? "aws-ecr-creds"
    , schedule ? "0 */8 * * *"
    , failedJobsHistoryLimit ? 1
    , successfulJobsHistoryLimit ? 1
    , extra ? { }
    }:
    let
      sa = components.service-account { inherit name namespace; };
      role = components.role { inherit name namespace; rules = [{ apiGroups = [ "" ]; resources = [ "secrets" ]; verbs = [ "get" "list" "create" "patch" "update" "delete" ]; }]; };
      rb = {
        apiVersion = "rbac.authorization.k8s.io/v1";
        kind = "RoleBinding";
        metadata = {
          inherit name namespace;
        };
        roleRef = {
          inherit name;
          apiGroup = "rbac.authorization.k8s.io";
          kind = "Role";
        };
        subjects = [{ inherit namespace; kind = "ServiceAccount"; name = "${name}-sa"; }];
      };
      secret_name = "aws-registry";
      secret_opts = concatStringsSep " " [
        "--docker-server=https://${account_id}.dkr.ecr.${region}.amazonaws.com"
        "--docker-username=AWS"
        "--docker-password=$(aws ecr get-login-password --region ${region})"
        "--docker-email=no@email.local"
      ];
      script = concatStringsSep " && " [
        "kubectl delete secret ${secret_name} || true"
        "kubectl create secret docker-registry ${secret_name} ${secret_opts}"
      ];
      cron = hex.k8s.cron.build {
        inherit name namespace schedule failedJobsHistoryLimit successfulJobsHistoryLimit extra;
        cpuLimit = "500m";
        memoryLimit = "512Mi";
        ephemeralStorageLimit = "100Mi";
        image = "${image}:${image_tag}";
        sa = "${name}-sa";
        command = "/bin/bash";
        args = [ "-c" script ];
        envFrom = [{
          secretRef = {
            name = aws_secret;
          };
        }];
      };
    in
    ''
      ${toYAMLDoc sa}
      ${toYAMLDoc role}
      ${toYAMLDoc rb}
      ${cron}
    '';

  mountpoint-s3-csi-driver = {
    chart =
      let
        name = "aws-mountpoint-s3-csi-driver";
      in
      rec {
        defaults = {
          inherit name;
          namespace = "kube-system";
        };
        version = rec {
          _v = hex.k8s._.version chart;
          latest = v1-11-0;
          v1-11-0 = _v "1.11.0" "0bc913wy3gk4p3d2vhpjax0g3696wnhxr5vcqzbih4ml24sa182a"; # 2024-12-05
        };
        chart_url = version: "https://github.com/awslabs/mountpoint-s3-csi-driver/releases/download/helm-chart-${name}-${version}/${name}-${version}.tgz";
        chart = hex.k8s._.chart { inherit defaults chart_url; };
      };

    # see examples here: https://github.com/awslabs/mountpoint-s3-csi-driver/tree/main/examples/kubernetes/static_provisioning
    bucket =
      { name
      , bucket
      , uid ? -1
      , gid ? -1
      , allowDelete ? false
      , allowOther ? true
      , prefix ? ""
      , extraMountOptions ? [ ]
      , namespace ? "default"
      , volumeHandle ? "s3-csi-${name}"
      , region ? "us-east-2"
      , pvSuffix ? "-pv"
      , pvcSuffix ? "-pvc"
      , accessMode ? "ReadWriteMany"
      }:
      let
        listIf = cond: value: if cond then value else [ ];
        pv_name = "${name}${pvSuffix}";
        pvc_name = "${name}${pvcSuffix}";
        size = "1234Gi"; # this is ignored, but a required field
        pv = {
          apiVersion = "v1";
          kind = "PersistentVolume";
          metadata = {
            name = pv_name;
          };
          spec = {
            accessModes = [ accessMode ];
            capacity.storage = size;
            claimRef = {
              inherit namespace;
              name = pvc_name;
            };
            csi = {
              inherit volumeHandle;
              driver = "s3.csi.aws.com";
              volumeAttributes.bucketName = bucket;
            };
            mountOptions = [ "region ${region}" ] ++
              (listIf allowDelete [ "allow-delete" ]) ++
              (listIf allowOther [ "allow-other" ]) ++
              (listIf (prefix != "") [ "prefix ${prefix}" ]) ++
              (listIf (uid != -1) [ "uid=${toString uid}" ]) ++
              (listIf (gid != -1) [ "gid=${toString gid}" ]) ++
              extraMountOptions;
            storageClassName = "";
          };
        };
        pvc = {
          apiVersion = "v1";
          kind = "PersistentVolumeClaim";
          metadata = {
            inherit namespace;
            name = pvc_name;
          };
          spec = {
            accessModes = [ accessMode ];
            resources.requests.storage = size;
            storageClassName = "";
            volumeName = pv_name;
          };
        };
      in
      ''
        ${toYAMLDoc pv}
        ${toYAMLDoc pvc}
      '';
  };
}
