# P2.2 · Review Cargo build and packaging outputs

**Access** — Offline. Allow 45–60 minutes. Use the [P2.1 Ledger Gateway workspace](p2-1-read-cargo-manifests-and-lockfile.md) as the baseline. Commands, configuration and trace excerpts are illustrative and unexecuted.

A release job reports a successful Windows build, but the collection step looks in the wrong directory. A separate job is asked to package the same CLI as a crate and fails on a local dependency. Determine which Cargo command produces each deliverable, where it goes, and which failure belongs to dependency resolution rather than compilation or packaging.

## Predict the build output

Assume the workspace root is the current directory, the Cargo host is `x86_64-pc-windows-msvc`, and the workspace uses the default target directory. No Cargo configuration or environment variables override the target triple or output directory. The `ledger-route` package has one binary from `src/main.rs`, named after the package. Extend the root manifest with this profile:

```toml
[profile.release-with-symbols]
inherits = "release"
debug = true
```

Cargo reads profiles from the workspace root. The custom profile inherits release settings and requests debug information. The custom name determines its output directory. The profile, selected workspace package and target triple are separate inputs. The host triple describes where the toolchain runs, while the target triple determines the platform for compiled output. Even an explicit target equal to the host adds a triple directory. [Cargo profiles](https://doc.rust-lang.org/cargo/reference/profiles.html), [Cargo build cache layout](https://doc.rust-lang.org/cargo/reference/build-cache.html)

| Illustrative invocation | What to expect |
|---|---|
| `cargo test --workspace --locked` | Selects both workspace members for testing. The default test profile inherits dev and uses the `target/debug/` directory. Test executables are distinct from the deployable release CLI. |
| `cargo build -p ledger-route --locked` | Selects the CLI package and builds the dependencies it needs, including `ledger-core`. The default dev output is `target/debug/ledger-route.exe`. |
| `cargo build -p ledger-route --release --locked` | Selects the release profile and writes `target/release/ledger-route.exe` with no explicit target or target override. |
| `cargo build -p ledger-route --release --target x86_64-pc-windows-msvc --locked` | Writes `target/x86_64-pc-windows-msvc/release/ledger-route.exe`. |
| `cargo build -p ledger-route --profile release-with-symbols --target x86_64-pc-windows-msvc --locked` | Writes `target/x86_64-pc-windows-msvc/release-with-symbols/ledger-route.exe`. |

In this virtual workspace, a root invocation without package selection defaults to all members because the root has no `default-members` setting. Prefer explicit package or workspace selection when reviewing CI so the intended scope is visible. If the trace and table disagree, check `CARGO_TARGET_DIR`, `build.target-dir`, `--target-dir` and configured target overrides before changing the artifact path. A machine-readable build trace with `--message-format=json` can identify the selected binary's `executable` in its compiler artifact message. [Cargo build package selection](https://doc.rust-lang.org/cargo/commands/cargo-build.html), [Cargo JSON messages](https://doc.rust-lang.org/cargo/reference/external-tools.html#json-messages)

A Maven reader can map workspace selection to a reactor build that selects modules. Maven profiles can alter the build model broadly. Cargo build profiles configure compilation settings such as optimization and debug information. Cargo feature flags and the target triple express separate choices.

## Review the release handoff

The synthetic trace records the release job's build command and the following failure:

```text
cargo build -p ledger-route --release --target x86_64-pc-windows-msvc --locked
Finished release profile
Collection step: target/release/ledger-route.exe was not found
```

The build used an explicit triple, but collection assumed the host-default layout. In the producing job, a reviewable fix is to stage the expected binary under a stable, project-relative handoff path. Keep the build's exit check before the copy so a stale executable cannot stand in for a failed build.

```powershell
cargo build -p ledger-route --release --target x86_64-pc-windows-msvc --locked
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$artifact = 'target/x86_64-pc-windows-msvc/release/ledger-route.exe'
New-Item -ItemType Directory -Path 'dist' -Force -ErrorAction Stop | Out-Null
Copy-Item -LiteralPath $artifact -Destination 'dist/ledger-route.exe' -ErrorAction Stop
```

The GitLab producer can then declare `dist/ledger-route.exe` as an artifact. A downstream job needs the producer's artifact transfer configured. A runner cache is reusable input and cannot establish which job produced the binary.

## Distinguish a binary from a crate archive

`cargo package -p ledger-core --list` lists the files selected for the archive. It helps detect missing sources or unintended files, but it does not create an archive or verify a build from it. A successful `cargo package -p ledger-core` creates `target/package/ledger-core-0.1.0.crate` under the assumed layout. Cargo normally verifies by extracting and building the package. The archive contains source and package metadata for distribution through a registry. It is a different deliverable from a Windows executable or a GitLab artifact bundle. Packaging itself does not publish the crate. [cargo package](https://doc.rust-lang.org/cargo/commands/cargo-package.html)

The P2.1 CLI manifest contains `ledger-core = { path = "../ledger-core" }`. That works in the checkout. Cargo requires a version for a normal path dependency when packaging for distribution. Adding a version alongside the path lets local builds use the checkout while the packaged manifest uses the version requirement. The registry selected for that dependency must actually provide a matching crate for verification and downstream consumers. Review that release ordering before changing the manifest. [Cargo dependency locations](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#multiple-locations)

## Diagnose a stale lockfile

Assume a merge request changes the shared Serde requirement from `"1.0.219"` to `"=1.0.220"`, while `Cargo.lock` still selects 1.0.219. A locked build stops because Cargo cannot satisfy the new requirement with the recorded version. The lockfile needs a deliberate update if the dependency change is intended. Review the manifest and lockfile diff together, including any changed transitive dependencies, then expect the locked build to pass dependency resolution with a valid lockfile and available registry data. If the manifest edit was accidental, revert it. Deleting the lockfile or dropping `--locked` in CI obscures the change the job was meant to catch. [Cargo locked mode](https://doc.rust-lang.org/cargo/commands/cargo-build.html)

## Offline review and worked answers

1. **Scope** — Does `cargo build -p ledger-route` select `ledger-core` as a top-level package?  
   **Answer** — The CLI is the selected package. Cargo builds the library because the CLI depends on it. Workspace-wide testing is a separate selection.
2. **Path** — A developer replaces `--release` with `--profile release-with-symbols` and keeps the target triple. Which path must collection use?  
   **Answer** — `target/x86_64-pc-windows-msvc/release-with-symbols/ledger-route.exe`. Adjust the source of the staged copy while keeping its handoff path stable.
3. **Package** — Why can the checkout compile while packaging the CLI fails?  
   **Answer** — The local path resolves inside the checkout. Distribution requires a versioned dependency that can be resolved without the sibling source tree. Review the packaged dependency's registry availability as well as its version requirement.
4. **Failure boundary** — How do you distinguish stale-lock failure from a missing executable after a successful build?  
   **Answer** — A stale lock fails during dependency resolution. In the trace above, Cargo finished and collection used the wrong directory. Compare the build exit and target/profile options before changing dependencies.

## Acceptance

Predict package selection, profile and artifact path from the command and assumptions. Explain which evidence separates a stale lockfile, a packaging dependency failure and a collection-path error. Identify which deliverable belongs to a Windows release and which belongs to a crate registry. Runtime practice is listed in [Future labs](../../FUTURE-LABS.md).
