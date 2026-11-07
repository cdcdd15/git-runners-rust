# P2.1 · Read Cargo manifests and a lockfile

**Access** — Offline. Allow 45–60 minutes. This exercise continues the [Ledger Gateway example](p1-1-read-a-rust-library-and-cli.md). The manifests, lockfile excerpt, mirror address and graph are illustrative and unexecuted. Assume a Cargo release that supports resolver 2, sparse registries and lockfile format 4. Read the examples as repository files and job evidence.

A Windows pipeline and a library-only check both use the same checkout and lockfile. The pipeline enables a reporting feature and sees an extra derive dependency. A reviewer thinks someone changed the lockfile or downloaded Serde from a different registry. Trace three separate inputs to the build: the manifests constrain the resolution, the lockfile records package identities, and the selected packages and features determine what this invocation uses.

## Manifests · Locate the dependency and feature edges

```toml
# Cargo.toml at the repository root
[workspace]
members = ["crates/ledger-core", "crates/ledger-route"]
resolver = "2"

[workspace.dependencies]
serde = "1.0.219"
```

```toml
# crates/ledger-core/Cargo.toml
[package]
name = "ledger-core"
version = "0.1.0"
edition = "2021"

[dependencies]
serde = { workspace = true }
```

```toml
# crates/ledger-route/Cargo.toml
[package]
name = "ledger-route"
version = "0.1.0"
edition = "2021"

[dependencies]
ledger-core = { path = "../ledger-core" }
serde = { workspace = true }

[features]
derive-report = ["serde/derive"]
```

The root is a virtual manifest because it has no `[package]` section. It lists the two workspace members, sets the resolver explicitly and centralizes the Serde requirement. A member inherits that requirement only when it opts in with `workspace = true`. The CLI's path dependency points to the library within the checkout. Serde's version requirement `"1.0.219"` is a caret requirement, which permits compatible later versions below 2.0.0. The lockfile determines the exact version selected for this checkout.

The CLI's `derive-report` feature requests Serde's `derive` feature. Serde 1.0.219 enables `std` by default and adds its derive macro dependency when `derive` is activated. With both workspace members selected and the reporting feature enabled, their normal edges to the same Serde package contribute to one feature set in this fixture. A library-only invocation lacks the CLI feature request. Resolver 2 still unifies these normal edges. It separates some other contexts, including features on build dependencies and proc macros from features on normal dependencies. [Cargo workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html), [version requirements](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html), [dependency resolver](https://doc.rust-lang.org/cargo/reference/resolver.html), [Serde 1.0.219 manifest](https://github.com/serde-rs/serde/blob/v1.0.219/serde/Cargo.toml)

For a Maven reader, workspace membership resembles reactor membership, and `[workspace.dependencies]` resembles central dependency management. Cargo features are additive requests on packages in the dependency graph. Think of them as capabilities requested along dependency edges. A Maven profile may change project configuration or dependencies, but it does not explain Cargo's feature union across dependents.

## Lockfile · Read what is resolved

```toml
# Cargo.lock at the repository root, excerpt
# Registry checksums and transitive entries are omitted for reading.
version = 4

[[package]]
name = "ledger-core"
version = "0.1.0"
dependencies = ["serde"]

[[package]]
name = "ledger-route"
version = "0.1.0"
dependencies = ["ledger-core", "serde"]

[[package]]
name = "serde"
version = "1.0.219"
source = "registry+https://github.com/rust-lang/crates.io-index"
dependencies = ["serde_derive"]

[[package]]
name = "serde_derive"
version = "1.0.219"
source = "registry+https://github.com/rust-lang/crates.io-index"
```

The two local packages have no registry source in the excerpt. The Serde entry selects version 1.0.219 from the crates.io source. Cargo resolves the lockfile as though all workspace member features were enabled so optional dependencies can be resolved ahead of use. The derive package can appear in the lockfile even when a particular command does not activate it. Use the lockfile for resolved package identities, and use a feature-aware graph for the selected build. `--locked` requires a present lockfile that Cargo can use without changing it. It can still need to fetch index or package data. [Cargo lockfile and feature resolution](https://doc.rust-lang.org/cargo/reference/resolver.html), [cargo metadata options](https://doc.rust-lang.org/cargo/commands/cargo-metadata.html)

## Registry configuration · Follow the source to the mirror

```toml
# .cargo/config.toml at the repository root
[source.crates-io]
replace-with = "corporate-mirror"

[source.corporate-mirror]
registry = "sparse+https://cargo-mirror.example.invalid/index/"
```

For commands launched from the workspace root in this fixture, Cargo reads the repository configuration and uses the equivalent mirror for crates.io. The lockfile still shows crates.io package identity. Its source string cannot prove which endpoint the runner contacted, or whether an existing cache avoided a request. Verify the job's working directory and effective Cargo configuration before investigating network or certificate errors. The mirror is assumed to contain equivalent crates.io content. Company-only crates would use an alternate registry configured through `[registries]` and selected on the dependency with `registry = "..."`. Keep credentials out of repository configuration and review them under the approved credential policy. [Source replacement](https://doc.rust-lang.org/cargo/reference/source-replacement.html), [Cargo configuration](https://doc.rust-lang.org/cargo/reference/config.html), [alternate registries](https://doc.rust-lang.org/cargo/reference/registries.html)

## Predict the graph

These example commands show what to look for in an existing job. The graph column is a reading aid and is not captured command output.

| Example command | Evidence to look for |
|---|---|
| `cargo metadata --locked --format-version 1` | JSON with both workspace member IDs, package records and dependency resolution data. Use `workspace_members` to distinguish workspace packages from registry dependencies. |
| `cargo tree --locked -p ledger-core -e features -i serde` | The library requests Serde's defaults, including `std`. No edge from the CLI requests `derive` in this invocation. |
| `cargo tree --locked --workspace --features ledger-route/derive-report -e features -i serde` | The CLI adds `derive` through `ledger-route/derive-report`. In this graph the shared normal Serde dependency has both `std` and `derive`. |

The inverse feature view helps locate who requested a feature. Match the job's package selection, feature flags and target when interpreting a graph from another invocation. Cargo documents that the tree view approximates a build graph and can differ in edge cases. [cargo tree](https://doc.rust-lang.org/cargo/commands/cargo-tree.html), [Cargo features](https://doc.rust-lang.org/cargo/reference/features.html)

## Offline exercise and worked answers

1. **Trace the path.** Why does Serde appear when building `ledger-route`?  
   **Answer** — The CLI inherits Serde directly and also reaches it through the local `ledger-core` path dependency. Both normal edges resolve to the same Serde package in the fixture.
2. **Explain the extra derive dependency.** Why can `serde_derive` appear in the lockfile but stay inactive for the library-only job?  
   **Answer** — The lockfile accounts for optional workspace features. The library-only job activates the default Serde features without the CLI's request for `derive`. Adding that request to the workspace invocation changes feature activation without requiring a version change.
3. **Review a fragile change.** A developer adds an unconditional `serde::Serialize` derive to the library after seeing the workspace reporting job pass. What check exposes the missing declaration?  
   **Answer** — A library-only build without the CLI feature exposes the missing macro. The library should request `serde/derive` itself if the macro is required unconditionally. If the derive is optional, gate its use and forward the dependency feature from the library's own feature.
4. **Investigate a mirror error.** The job trace reports a certificate failure at the mirror URL while the lockfile shows crates.io. Which evidence takes priority for diagnosing the connection?  
   **Answer** — The URL in the failure identifies the endpoint involved. Confirm source replacement and inspect CA or proxy settings for the failing Cargo invocation. Keep the lockfile identity intact while diagnosing transport.
5. **Review a version edit.** A merge request changes the shared requirement to `"=1.0.220"` but the lockfile still selects 1.0.219. What happens under `--locked`?  
   **Answer** — The selected version no longer satisfies the manifest. A locked resolution cannot succeed with that mismatch. Review a deliberate lockfile update alongside the manifest edit.

## Acceptance

Explain the two edges to Serde, why the selected version can stay fixed while features change, and how to identify the actual fetch endpoint. Classify a lockfile mismatch, a missing feature request and a mirror transport failure using the evidence above. Continue with [P2.2](../roadmap/P2.md#p22--review-build-and-packaging-outputs) for build profiles, targets and packaging.
