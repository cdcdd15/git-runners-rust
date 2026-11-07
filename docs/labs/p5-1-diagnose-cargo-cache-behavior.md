# P5.1 · Diagnose Cargo cache behavior from traces

**Access** — Offline. Allow 45–60 minutes. Start with [Cargo resolution and registry selection](p2-1-read-cargo-manifests-and-lockfile.md) and the [GitLab execution sequence](../architecture/README.md). The YAML, cache keys, runner names and traces below are illustrative and unexecuted.

Ledger Gateway uses two Windows Shell runners. One job fetches dependency inputs, and a later job runs locked workspace tests. The team wants faster builds while preserving a successful cold path. A cache hit is evidence that Runner restored an archive for a key. Inspect what the job needed and what Cargo did before treating that hit as useful.

## Follow the data across job boundaries

Runner checks out the source, restores a configured cache and downloads any configured upstream artifacts before running the script. It may save a cache after the script, depending on policy and job outcome. A cache is reusable data. It can be absent because the key changed, the archive expired, the reader cannot reach the backend or the producer ran on another machine. It should improve performance without becoming a required input to correctness. [GitLab cache behavior](https://docs.gitlab.com/ci/caching/), [job execution flow](https://docs.gitlab.com/ci/jobs/job_execution/)

| Item | Use in this exercise |
|---|---|
| `CARGO_HOME/registry/index/` | Registry metadata and index cache. |
| `CARGO_HOME/registry/cache/` | Downloaded crate archives. Cargo can extract them on demand. |
| `CARGO_HOME/registry/src/` | Extracted sources. Excluded here to avoid storing source bytes twice. |
| `CARGO_HOME/credentials.toml` | Credential material. Excluded by selecting only the two registry paths. |
| Workspace `target/` | Compilation output and intermediates. Excluded from this dependency cache. A release executable belongs in a producer artifact with build provenance. |

A Maven reader can think of Cargo's registry directories as playing a role similar to the download portion of the local Maven repository. The GitLab cache is a separate archive mechanism that transports selected directories. A warm Cargo registry can avoid dependency downloads while the job still compiles the workspace. The fixture assumes registry dependencies and local workspace members. Git dependencies would need a separately reviewed cache layout. [Cargo home](https://doc.rust-lang.org/cargo/guide/cargo-home.html), [Cargo build cache](https://doc.rust-lang.org/cargo/reference/build-cache.html)

## Review the proposed cache configuration

Assume the repository has a committed `Cargo.lock` and the reviewed `.cargo/config.toml` from P2.1. The `windows-rust` pool uses the same approved Rust toolchain and Windows MSVC environment. The job identity can reach the approved registry on a cold run. A distributed cache or shared cache location is assumed for cross-host restores. With local-only storage, a consumer on another runner can miss.

```yaml
stages: [prepare, test]

default:
  tags: [windows-rust]
  before_script:
    - $env:CARGO_HOME = Join-Path $env:CI_PROJECT_DIR '.cargo-ci'
  cache:
    key:
      prefix: cargo-registry-win-msvc-v1
      files:
        - Cargo.lock
        - .cargo/config.toml
    paths:
      - .cargo-ci/registry/index/
      - .cargo-ci/registry/cache/
    policy: pull

warm_registry:
  stage: prepare
  cache:
    key:
      prefix: cargo-registry-win-msvc-v1
      files:
        - Cargo.lock
        - .cargo/config.toml
    paths:
      - .cargo-ci/registry/index/
      - .cargo-ci/registry/cache/
    policy: pull-push
  script:
    - cargo fetch --locked

test_workspace:
  stage: test
  script:
    - cargo test --workspace --locked
```

Both jobs use the same project-relative paths and key inputs. Runner restores those paths before the script sets `CARGO_HOME`, and Cargo then reads and writes the restored directory. The prefix describes the cache purpose, runner family and layout revision. The content-derived key changes with the lockfile or tracked registry configuration. If a listed file is missing, it is ignored in key calculation. With neither file present, the key uses the documented default component. Check that both files exist in the checkout and bump the prefix if the layout or compatibility contract changes outside those files. [Cache keys and policies](https://docs.gitlab.com/ci/yaml/#cache)

The warming job is the only writer **within a pipeline**. It replaces the entire `default:cache` value, so the replacement repeats the key and paths as well as changing the policy. Test jobs inherit `pull` and cannot overwrite the archive. `pull-push` restores and can upload, `pull` restores only, and `push` uploads only. Concurrent pipelines may still write to the same key. Each consumer must tolerate missing or incomplete cached inputs and fetch what it needs. The stage barrier gives the writer a chance to upload before the test job starts. The barrier cannot guarantee a hit on the next host.

GitLab can separate caches for protected and non-protected contexts and apply suffixes and cache-clear indexes. Check the effective key printed by Runner and the target version's behavior. Preserve the separation when reasoning about shared storage. A key prefix helps organize cache compatibility, while runner and backend permissions determine which jobs can read and write cached data. [GitLab cache separation and clearing](https://docs.gitlab.com/ci/caching/)

## Worked trace cases

Key labels are shortened. Archive existence, cache location and Cargo output are supplied evidence for this exercise.

| Case | Observations | Diagnosis and next check |
|---|---|---|
| Cold writer | New lockfile digest `L2`. Runner reports no archive. Cargo fetches locked crates and Runner uploads an archive. | Expected cold miss after key invalidation. Check upload success and the effective key before predicting that a reader can restore it. |
| Warm reader | Same effective `L2` key on a second host with the same distributed backend. Restore succeeds. Cargo compiles and no dependency download appears. | Useful warm dependency restore. Compilation still occurs because the archive contains registry data rather than `target/`. |
| Miss on another host | Writer uploaded a local archive on `win-01`. Reader on `win-02` reports the same effective key and no distributed cache URL. | Runner locality explains the miss. Confirm both jobs' actual backend and shared-storage configuration. A matching key cannot move a local archive. |
| Stale restore under an old policy | A legacy job restored `key: shared` and a cached `dist/ledger-route.exe`. The archived commit marker says `A`, while checkout is commit `B`. | The restore succeeded, but the binary belongs to another revision. The legacy job copied directly from cache without a current build. Remove release outputs from cache and use a producer artifact tied to the expected commit. |
| Restored archive with downloads | Runner extracts a matching archive, but Cargo still downloads dependencies. | Check the effective `CARGO_HOME`, restored directory names, registry source and whether the writer fetched the required crates. A partial archive can still be useful. |

## Review questions

1. **The cache stopped hitting after a registry mirror migration, but the lockfile is unchanged. What should you compare?**  
   **Answer** — Compare the tracked Cargo config and effective key, then check source selection and cache path on both jobs. The fixture intentionally creates a new key when the tracked config changes. A host-side override can change source behavior without changing that file.
2. **A teammate changes only the test job's policy to `pull-push`. What could change?**  
   **Answer** — The test becomes another writer and may overwrite the warm archive. Define which job owns writes and keep readers on `pull` unless the workflow explicitly needs them to populate caches.
3. **Should a locked build add `--offline` because a restore was reported as successful?**  
   **Answer** — The lockfile constrains resolution, and cache restore does not prove every required crate and index entry is available. Keep the cold path functional. An offline build needs a separate guarantee that all inputs are present.
4. **Which evidence should be compared before clearing a cache?**  
   **Answer** — Compare effective keys, writer and reader policies, cache scope, backend and restored paths. Clear or revise a key when the evidence identifies an invalid archive or changed layout. A scope or backend mismatch needs a different correction.

## Acceptance

Distinguish an expected miss, a useful warm restore, a locality miss and a stale hit using the trace evidence. Explain what changes the proposed key, why the reader does not write, and how to preserve a reliable cold path. Continue with [P5.2](../roadmap/P5.md#p52--trace-artifacts-and-dependency-edges) for artifact provenance and transfer.
