# [toolhive](https://github.com/stacklok/toolhive) makes deploying MCP servers easy, secure and fun
{ hex, ... }:
let
  _namespace = "toolhive-system";
in
{
  crds =
    let
      defaults = {
        namespace = _namespace;
        name = "toolhive-operator-crds";
      };
    in
    rec {
      version = rec {
        _v = hex.k8s._.version chart;
        latest = v0-0-9;
        v0-0-9 = _v "0.0.9" "sha256-b1BynUY3//GIVVFBcebPoQjnN9gYtZnJAPAFRGGoBEk=";
      };
      chart_url = version: "oci://ghcr.io/stacklok/toolhive/toolhive-operator-crds:${version}";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
  operator =
    let
      defaults = {
        namespace = _namespace;
        name = "toolhive-operator";
      };
    in
    rec {
      version = rec {
        _v = hex.k8s._.version chart;
        latest = v0-1-5;
        v0-1-5 = _v "0.1.5" "sha256-56xJAUzhdAPHlPwo/VYeeVu1j4lUMgfluAnPDGCSTaY=";
      };
      chart_url = version: "oci://ghcr.io/stacklok/toolhive/toolhive-operator:${version}";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
  mcp =
    let
      _mcp =
        { name
        , image
        , port ? 8080
        , transport ? "stdio"  # or sse
        , targetPort ? 8080    # if sse
        , env ? [ ]
        , envAttrs ? { }
        , secrets ? [ ]
        , namespace ? _namespace
        , permissionProfile ? {
            name = "network";
            type = "builtin";
          }
        , apiVersion ? "toolhive.stacklok.dev/v1alpha1"
        , cpuRequest ? "50m"
        , cpuLimit ? "200m"
        , memoryRequest ? "64Mi"
        , memoryLimit ? "256Mi"
        }: hex.toYAMLDoc {
          inherit apiVersion;
          kind = "MCPServer";
          metadata = {
            inherit name namespace;
          };
          spec = {
            inherit image port transport permissionProfile secrets;
            env = env ++ (hex.envAttrToNVP envAttrs);
            ${if transport == "sse" then "targetPort" else null} = targetPort;
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
          };
        };
      withDefaults = defaults: args: _mcp (defaults // args);
    in
    {
      __functor = _: _mcp;
      servers = {
        fetch = withDefaults {
          name = "fetch";
          image = "ghcr.io/stackloklabs/gofetch/server";
          transport = "sse";
        };
        github = withDefaults {
          name = "github";
          image = "ghcr.io/github/github-mcp-server";
          secrets = [{ name = "github-token"; key = "token"; targetEnvName = "GITHUB_PERSONAL_ACCESS_TOKEN"; }];
          env = hex.envAttrToNVP { GITHUB_API_URL = "https://api.github.com"; LOG_LEVEL = "info"; };
        };
      };
    };
}
