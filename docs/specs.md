# specs

## detailed example of a hex specs file

**Note: `specs.nix` is the default target when `hex` is run without a specific target (`-t TARGET_FILE`) or without `-a/--all`**

`specs.nix`:

```nix
{ hex }:
let
    # remember this is just nix code, so you can use any normal language features!
    inherit (hex.k8s.svc) metabase;
in
hex [
    # every entry in this list will be evaluated + rendered
    # lists will be flattened!

    # if an entry is a function, it will be called with an empty attrset
    hex.k8s.svc.litellm      # equivalent to: (hex.k8s.svc.litellm {})

    # pass attrs in to override default functionality, or to provide required attrs
    (metabase { domain = "metabase.cobi.dev"; })

    # if an entry is a yaml file path, it will be merged into the set of all rendered specs
    ./other_k8s_spec.yaml    # includes this file in the rendered output documents

    # also, use toYAMLDoc to use arbitrary attrsets!
    (hex.toYAMLDoc {
        apiVersion = "v1";
        kind = "ServiceAccount";
        metadata = {
            annotations.source = "hex";
            name = "my-service-account";
            namespace = "default";
        };
    })

    # TODO: show a helm chart example
]
```

## usage

```bash
# hex --help
Usage: hex [-t|--target VAR] [-a|--all] [-d|--dryrun] [-r|--render] [-c|--crds] [--clientside] [-p|--prettify] [-f|--force] [-e|--evaluate VAR] [--version]

a quick and easy way to render full kubespecs from nix files

Flags:
-t, --target          the file to render specs from [default: './specs.nix']
-a, --all             render all hex files in the current directory (ignoring gitignored files) [bool]
-d, --dryrun          just run the diff, don't prompt to apply [bool]
-r, --render          only render and patch, do not diff or apply [bool]
-c, --crds            filter down to just the CRDs (useful for initial deployments) [bool]
--clientside          run the diff on the clientside instead of serverside [bool]
-p, --prettify        whether to run prettier on the hex output yaml [bool]
-f, --force           force apply the resulting hex without a diff (WARNING - BE CAREFUL) [bool]
-e, --evaluate        evaluate an in-line hex script
--version             print version and exit [bool]
-h, --help            print this help and exit
-v, --verbose         enable verbose logging and info
--no-color            disable color and other formatting
```
