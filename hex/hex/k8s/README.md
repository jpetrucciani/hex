# k8s

hexes related to k8s specs and charts!

---

## In this directory

### [helm/](./helm/)

helm based hex modules

### [svc/](./svc/)

individual service hexes

### [addons.nix](./addons.nix)

various cluster addons [out of date]

### [aws.nix](./aws.nix)

This module contains k8s helpers for AWS related functionality

### [cert-manager.nix](./cert-manager.nix)

[cert-manager](https://github.com/cert-manager/cert-manager/) adds certificates and certificate issuers as resource types in Kubernetes clusters, and simplifies the process of obtaining, renewing and using those certificates.

### [cron.nix](./cron.nix)

This hex spell allows concise cron job declaration in Kubernetes.

### [helm.nix](./helm.nix)

This module allows us to transparently use [helm](https://github.com/helm/helm) charts in hex spells!

### [nginx-ingress.nix](./nginx-ingress.nix)

[nginx-ingress controller](https://github.com/kubernetes/ingress-nginx)

### [services.nix](./services.nix)

This module allows us to create best-practices, all-inclusive k8s services with a set of powerful nix functions.

### [storage.nix](./storage.nix)

helpers for defining PVs and PVCs

### [tailscale.nix](./tailscale.nix)

This module contains useful shorthands for using [tailscale](https://tailscale.com/) within kubernetes
