# P5.2 · Trace artifacts and dependency edges

**Access** — Offline. Allow 45–60 minutes. Start with [P5.1 cache behavior](p5-1-diagnose-cargo-cache-behavior.md) and the [Cargo release handoff](p2-2-review-cargo-build-and-packaging.md). All YAML, job IDs, commits and outcomes below are illustrative and unexecuted.

Ledger Gateway needs to hand off a Windows executable to a verification job. The executable must correspond to the consumer's commit even when no cache is available. A later integration project also consumes builds from Ledger Gateway and needs to distinguish the newest available build from a particular approved build.

## Same pipeline · Make the producer explicit

Assume a GitLab project with the Ledger Gateway workspace and an eligible `windows-rust` Shell runner using PowerShell Core. The complete illustrative file builds the Windows CLI, writes a commit marker and verifies the transfer. There is no cache configuration.

```yaml
stages: [build, verify]

default:
  tags: [windows-rust]

build_windows:
  stage: build
  script:
    - |
      cargo build -p ledger-route --release --target x86_64-pc-windows-msvc --locked
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

      New-Item -ItemType Directory -Path 'handoff' -Force -ErrorAction Stop | Out-Null
      Copy-Item -LiteralPath 'target/x86_64-pc-windows-msvc/release/ledger-route.exe' -Destination 'handoff/ledger-route.exe' -ErrorAction Stop
      Set-Content -LiteralPath 'handoff/build-commit.txt' -Value $env:CI_COMMIT_SHA -Encoding ascii -ErrorAction Stop
  artifacts:
    paths:
      - handoff/ledger-route.exe
      - handoff/build-commit.txt
    expire_in: 7 days

verify_handoff:
  stage: verify
  needs:
    - job: build_windows
      artifacts: true
  script:
    - |
      if (-not (Test-Path -LiteralPath 'handoff/ledger-route.exe' -PathType Leaf)) {
        throw "Expected executable is missing"
      }
      $producerCommit = (Get-Content -LiteralPath 'handoff/build-commit.txt' -Raw -ErrorAction Stop).Trim()
      if ($producerCommit -cne $env:CI_COMMIT_SHA) {
        throw "Artifact was built for a different commit"
      }
      Write-Host 'Artifact handoff verified'
```

On a successful build, Runner uploads the two declared files for `build_windows`. The explicit `needs` edge controls both scheduling and transfer. Once the producer succeeds and Runner prepares the consumer workspace, Runner downloads its artifact before PowerShell starts. The files can be transferred between different hosts without sharing Cargo's cache or working directory. The marker checks revision identity under the assumption that the producer and its pipeline are trusted. It does not independently authenticate the executable. In a review record, keep the producer project, pipeline and job IDs with the commit. [GitLab job artifacts](https://docs.gitlab.com/ci/jobs/job_artifacts/), [GitLab execution order](https://docs.gitlab.com/ci/jobs/job_execution/)

| Same-pipeline configuration | Scheduling | Artifact selection |
|---|---|---|
| Later-stage job with neither `needs` nor `dependencies` | Default stage ordering | Downloads available artifacts from earlier stages by default. |
| Later-stage job with `dependencies: [build_windows]` | Default stage ordering | Selects that earlier-stage producer for downloads. An empty list skips them. |
| Job with `needs: [{job: build_windows, artifacts: true}]` | Can start when its DAG prerequisites are satisfied | Downloads from that edge. A job using `needs` no longer implicitly downloads from every earlier stage. |
| Same edge with `artifacts: false` | Still waits for the producer | Skips the download. Use only when ordering is sufficient. |

Choose one selection mechanism per job. GitLab advises against combining `needs` and `dependencies`. If multiple producers upload a path with the same name, review possible overwrite and use distinct output paths. A Maven reactor may make locally built modules available during one build invocation. Separate CI jobs need an explicit handoff when one job requires a particular producer's output. [GitLab YAML reference](https://docs.gitlab.com/ci/yaml/)

## Cross-pipeline · Choose the identity before choosing the mechanism

### Parent to child

In an alternative parent configuration, keep `build_windows` from the first example. The following trigger is in the later `verify` stage, so the producer has completed before the child is created under normal stage ordering.

```yaml
start_child:
  stage: verify
  variables:
    PARENT_PIPELINE_ID: $CI_PIPELINE_ID
  trigger:
    include: ci/verify-child.yml
```

A child job in `ci/verify-child.yml` can request the artifact by parent pipeline ID and job name. The excerpt assumes the child runs on the same project's eligible Windows pool.

```yaml
inspect_parent_build:
  tags: [windows-rust]
  needs:
    - pipeline: $PARENT_PIPELINE_ID
      job: build_windows
  script:
    - Get-Item -LiteralPath 'handoff/ledger-route.exe' -ErrorAction Stop
```

`needs:pipeline:job` can retrieve a successful producer's artifact from a parent or another child in the same hierarchy. Review how the producer is ordered before the consumer. The retrieval reference does not replace that ordering. Use the same marker check as the first example if the parent and child are expected to share a commit. [GitLab parent-child artifact retrieval](https://docs.gitlab.com/ci/yaml/#needspipelinejob)

### Separate project

Use this excerpt only when the downstream requirement is the **latest successful run of a named upstream job on a ref**. GitLab documents `needs:project` for Premium and Ultimate. The consumer needs appropriate access to upstream artifacts. Check the producer project's visibility, artifact access restrictions and the permissions of the identity running the pipeline.

```yaml
inspect_upstream_build:
  tags: [windows-rust]
  needs:
    - project: platform/ledger-gateway
      job: build_windows
      ref: main
      artifacts: true
  script:
    - Get-Item -LiteralPath 'handoff/ledger-route.exe' -ErrorAction Stop
```

If `main` points to commit B and its build is still running, this edge can fetch the last successful build from commit A. It does not wait for B. The consumer's `CI_COMMIT_SHA` identifies its own project and may differ by design. For an exact handoff, pass an approved upstream commit together with an explicit producer project and job ID, retrieve by job ID using the authorized [Job Artifacts API](https://docs.gitlab.com/api/job_artifacts/), and compare the marker to that upstream commit. Review the API authentication, tier and cross-project access controls before using it. [GitLab needs:project behavior](https://docs.gitlab.com/ci/yaml/#needsproject)

## Retention and troubleshooting

The example requests seven days of retention. Actual availability also depends on project or instance settings for retaining recent artifacts, manual retention, and whether the artifact was erased. Verify the producer's current artifact record before assuming the age alone proves expiration. Keep release distribution and its retention contract separate from short-lived CI handoffs. [GitLab artifact retention](https://docs.gitlab.com/ci/jobs/job_artifacts/)

| Evidence | Next check |
|---|---|
| Producer passed, but trace warns that no artifact files matched | Compare build output and declared paths relative to the checkout. Confirm both files were staged before upload. |
| Consumer fails during artifact download, before PowerShell | Identify the referenced job and artifact record. Check retention, deletion and access before changing the consumer script. |
| Consumer reaches PowerShell with missing files | Check the effective download selection, `artifacts: false`, archive paths and workspace cleanup. |
| Files download, but marker is wrong | Check producer job ID and commit. In a cross-project ref lookup, distinguish latest successful job from the intended upstream build. |
| Cache is empty but download succeeds | Expected. Confirm the explicit artifact transfer and commit marker instead of relying on working-directory persistence. |

## Offline review and worked answers

1. **An earlier lint stage becomes slower. Does `verify_handoff` wait for an unrelated job just because it is in an earlier stage?**  
   **Answer** — The consumer's direct DAG prerequisite is `build_windows`. It still waits indirectly for any prerequisite of that producer. Draw both the direct and transitive edges before predicting timing.
2. **The producer publishes successfully and the consumer changes to `artifacts: false`. What happens on a clean checkout?**  
   **Answer** — The consumer still waits for the producer. Its script fails the file check because it never downloads the executable.
3. **A cross-project reader requests `main` while B is building. A is the last successful build. Which result is selected?**  
   **Answer** — The ref-based edge selects A. To require B, first establish its successful producer job, retrieve by that job ID under the approved access rules, and verify B's marker.
4. **A one-week-old artifact is still visible. Which evidence matters?**  
   **Answer** — Check the artifact's job and retention state, recent-artifact settings and any manual keep decision. The configured expiry alone does not establish whether a file is available.

## Acceptance

Explain the exact producer, expected revision, transfer edge and retention evidence for each case. Show why the same-pipeline consumer works with an empty cache. Distinguish an artifact that was never uploaded, one that cannot be retrieved, and one that was retrieved from the wrong revision. Runtime practice remains in [Future labs](../../FUTURE-LABS.md).
