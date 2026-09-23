# basic examples

## [LiteLLM](https://github.com/BerriAI/litellm)

Below, we render out a _best-practices_[^1] implementation of a [LiteLLM](https://github.com/BerriAI/litellm) deployment for k8s!

### simplest hex spec example

#### use all default options

```nix
{hex}:
hex [
  hex.k8s.svc.litellm
]
```

#### customize some stuff

As you can with almost all hex modules/functions, you can override as much as you'd like from the defaults! You can see the available options within the module spec provided for each workload. Not all options are represented, and there is normally a set of escape hatches you can use to achieve any affect you may want (see things like `extraService`, which is usually an option among services in hex) - but if some functionality is missing or not easily exposed, please feel free to raise an [Issue](https://github.com/jpetrucciani/hex/issues) or [PR](https://github.com/jpetrucciani/hex/pulls)!

```nix
{hex}:
hex [
  (hex.k8s.svc.litellm {
    namespace = "ai";
    replicas = 3;
  })
]
```

#### include a small Valkey instance

LiteLLM recommends Redis-compatible shared state when it runs multiple workers or replicas. The bundled Valkey instance is off by default. Enable it like this:

```nix
{hex}:
hex [
  (hex.k8s.svc.litellm {
    namespace = "ai";
    replicas = 3;
    valkey.enable = true;
  })
]
```

Add a strong random `REDIS_PASSWORD` key to the existing `litellm-secret` in the same namespace before applying this spec. Set `valkey.passwordSecretName` and `valkey.passwordSecretKey` to use another Secret. Both pods read that key at startup; Hex does not write the password into the rendered config.

This option adds a single-replica Valkey StatefulSet, a 1Gi PVC, a headless Service, and a NetworkPolicy that admits traffic from the LiteLLM pods. It enables LiteLLM router coordination and Redis response caching with a 600-second TTL, configurable with `valkey.cacheTtl`. Valkey uses AOF persistence and `noeviction` so its shared coordination keys are not silently discarded. The default memory cap is 256mb; size `valkey.maxmemory`, `valkey.memoryLimit`, and `valkey.storage` for your workload. Use `valkey.storageClass` if the cluster has no suitable default StorageClass.

This is a single point of failure. Use an external managed Redis-compatible service for high availability. Choose `valkey.storage` before the first deployment; changing a StatefulSet's claim template later needs a separate PVC migration or expansion procedure. StatefulSet PVCs are retained by Kubernetes when the bundled option is removed; preserve or remove the claim deliberately. Restart both workloads after changing the password Secret.

### simple eval example

You can also use the `--evaluate` flag (with or without `--render`) to do one-liner bash commands that can output templates!

**Note: `--render` will print the output directly to stdout - if not passed, `hex` defaults to attempting to diff+apply to the currently active kubecontext!**

```bash
# longhand
hex --render --evaluate 'hex [hex.k8s.svc.litellm]'

# shorthand
hex -r -e 'hex [hex.k8s.svc.litellm]'
```

[^1]: Obviously, hex is not trying to claim or define the ultimate _best practices_ for k8s - but this gets you a saner default than many other systems.
