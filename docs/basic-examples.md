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
