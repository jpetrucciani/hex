{ pkgs }:
let
  inherit (builtins) attrNames concatLists filter fromJSON head length listToAttrs readDir readFile;
  inherit (pkgs.lib) hasSuffix removeSuffix sort unique;

  helmRoot = ./helm;
  svcRoot = ./svc;
  helmDirEntries = readDir helmRoot;
  svcDirEntries = readDir svcRoot;

  baseK8sModules = [
    "addons"
    "aws"
    "cron"
    "helm"
    "nginx-ingress"
    "services"
    "storage"
    "svc"
    "tailscale"
  ];

  helmEntries = attrNames helmDirEntries;
  svcEntries = attrNames svcDirEntries;

  helmRelevantEntries = filter (name: (helmDirEntries.${name} == "directory") || (hasSuffix ".nix" name)) helmEntries;

  helmModules = unique (map (name: if hasSuffix ".nix" name then removeSuffix ".nix" name else name) helmRelevantEntries);
  svcModules = map (name: removeSuffix ".nix" name) (filter (name: hasSuffix ".nix" name) svcEntries);

  versionDetails = rows:
    let
      latest = if rows == [ ] then null else (head rows).version;
    in
    {
      inherit latest;
      total = length rows;
      versions = map (x: x.version) rows;
    };

  helmVersioned =
    let
      dirs = filter (name: helmDirEntries.${name} == "directory") helmEntries;
      rows = concatLists (map
        (dir:
          let
            dirPath = helmRoot + "/${dir}";
            files = attrNames (readDir dirPath);
            jsonFiles = filter (name: hasSuffix ".json" name) files;
            oneVersionFile = length jsonFiles == 1;
          in
          map
            (jsonFile:
              let
                key = if oneVersionFile then "hex.k8s.${dir}" else "hex.k8s.${dir}.${removeSuffix ".json" jsonFile}";
                parsed = fromJSON (readFile (dirPath + "/${jsonFile}"));
              in
              {
                name = key;
                value = (versionDetails parsed) // {
                  source = "hex/hex/k8s/helm/${dir}/${jsonFile}";
                };
              }
            )
            jsonFiles
        )
        dirs);
    in
    listToAttrs rows;
in
{
  k8s = {
    topLevelModules = sort builtins.lessThan (baseK8sModules ++ helmModules);
    inherit svcModules helmModules helmVersioned;
  };
}
