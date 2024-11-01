---
layout: home

hero:
  name: 'hex 🪄'
  text: 'Nix-powered k8s configuration magic'
  tagline: Transform your Kubernetes workload manifests into concise, reproducible, configurations using the power of Nix
  actions:
    - theme: brand
      text: Get Started
      link: /getting-started
    - theme: alt
      text: View on GitHub
      link: https://github.com/jpetrucciani/hex
  # image:
  #   src: /hex-logo.png
  #   alt: hex

features:
  - icon: 🎯
    title: Declarative Configuration
    details: Define your entire Kubernetes infrastructure using Nix's powerful expression language. No more YAML nightmares! Make things DRY!

  - icon: 🔄
    title: Smart Diffing & Deployment
    details: See exactly what changes will be applied to your cluster with built-in diffing support. Choose between client-side or server-side comparisons.

  - icon: 📦
    title: Extensive Service Catalog
    details: Deploy popular services like ArgoCD, Prometheus, PostgreSQL, and more with pre-configured, production-ready templates.

  - icon: 🎨
    title: Helm Integration
    details: Seamlessly integrate Helm charts while maintaining declarative control and reproducibility through Nix.

  - icon: 🚀
    title: Interactive Workflow
    details: Review and approve changes before they're applied, with support for dry-runs and force deployments when needed.

  - icon: 🌟
    title: Extensible Architecture
    details: Easily extend hex with custom services, operators, and configurations to match your infrastructure needs.
---
