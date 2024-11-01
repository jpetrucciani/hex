# What is `hex`?

`hex` is a powerful configuration management tool built on [Nix](https://nixos.org/) that provides a declarative way to manage [Kubernetes](https://kubernetes.io/) resources and other configuration files. It acts as an abstraction layer that leverages Nix's reproducible builds and functional approach to create, manage, and deploy Kubernetes specifications and other configuration types. At its core, hex is both a command-line tool ([built with pog!](https://pog.gemologic.dev/)) and a framework that helps teams manage complex Kubernetes deployments with confidence.

## What does it enable?

Hex enables teams to:

1. Define Kubernetes resources using Nix's powerful functional language
2. Compose and manage complex Kubernetes deployments through modular "spells" (configuration files)
3. Render various configuration formats (YAML, JSON) from Nix expressions
4. Manage multiple services and their dependencies in a consistent way
5. Deploy and update Kubernetes resources with built-in safety checks and diffing
6. Integrate with popular tools like [Helm](https://github.com/helm/helm) charts while maintaining reproducibility
7. Create reusable abstractions for common deployment patterns
8. Handle environment-specific configurations through parametrization

The tool provides a suite of helper functions and utilities that make it easier to work with Kubernetes resources, Helm charts, and other configuration types, while maintaining the benefits of Nix's pure functional approach.

## Why use hex? What benefits do we get?

Using hex provides several key benefits:

### Reproducibility

One of the most significant advantages of hex is its foundation in Nix, which ensures completely reproducible configurations. Every aspect of your Kubernetes deployments, from the base images to the configuration files, can be precisely version-controlled and reproduced exactly as specified. This eliminates the "works on my machine" problem and ensures consistent deployments across different environments.

### Modularity and Composition

Hex allows you to break down complex configurations into manageable, reusable components. You can compose these components together using Nix's functional approach, making it easier to maintain and scale your infrastructure as it grows.

### Validation

By leveraging Nix's type system, hex helps catch configuration errors early in the development process, before they reach your clusters. This provides an additional layer of safety when managing complex Kubernetes deployments.

### Version Control and Tracking

Every change to your configuration is trackable and reversible. Hex's integration with Nix means that your entire configuration state is captured in version control, making it easy to audit changes and roll back when needed.

### Simplified Deployment Management

Hex provides built-in tools for comparing configurations (diffing), applying changes safely, and managing multiple environments. Its CLI interface makes it easy to visualize changes before they're applied and ensure that deployments are handled consistently.

### Enhanced Security

By using Nix's functional approach, hex helps prevent side effects and ensures that configurations are immutable. This makes it easier to maintain security best practices and audit your infrastructure.

## Why is it called hex?

The name "hex" is a clever play on words that works on multiple levels:

1. In fantasy and folklore, a "hex" is a magical spell or enchantment. This aligns with how the tool treats configuration files as "spells" that can be cast to create or modify resources in your Kubernetes clusters.

2. The tool's ability to transform Nix expressions into various configuration formats (like YAML or JSON) is similar to how a hex (spell) transforms one thing into another.

This naming reflects the tool's purpose of taking complex configuration management and making it feel as straightforward as casting a spell, while still maintaining the technical rigor and reproducibility that comes from its Nix foundation.
