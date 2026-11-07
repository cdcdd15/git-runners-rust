# P0.2 · Read an enterprise pipeline from event to result

**Access** — Offline. Allow 35–45 minutes. Read [P0.1](p0-1-job-trace.md) first.

A pipeline ties a commit and event to a set of jobs. GitLab decides which jobs exist and when they become eligible. Runner requests eligible work and prepares the executor. For this example, the Shell executor runs PowerShell Core on a Windows host under the Runner service identity. Compare this with Maven's lifecycle inside one JVM build invocation. A GitLab stage can span independent jobs, each with its own checkout, process and transfer steps. [GitLab pipelines](https://docs.gitlab.com/ci/pipelines/), [job execution flow](https://docs.gitlab.com/ci/jobs/job_execution/)

## Complete illustrative .gitlab-ci.yml

Assume a repository with a committed Cargo.lock, tests, and an eligible project runner with the `windows-rust` tag, Shell executor, `pwsh` and Cargo installed for its service identity. The tag selects an eligible runner. The runner's configuration determines its shell. This file is an unexecuted teaching example.

```yaml
workflow:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_PIPELINE_SOURCE == "push" && $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

stages: [prepare, test]

default:
  tags: [windows-rust]

record_revision:
  stage: prepare
  script:
    - Set-Content -LiteralPath build-commit.txt -Value $env:CI_COMMIT_SHA
  artifacts:
    paths: [build-commit.txt]
    expire_in: 1 day

test_rust:
  stage: test
  needs:
    - job: record_revision
      artifacts: true
  script:
    - |
      $revision = Get-Content -LiteralPath build-commit.txt
      if ($revision -ne $env:CI_COMMIT_SHA) {
        throw "Artifact commit does not match the tested commit"
      }
      cargo test --locked
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

| Configuration | When it matters | Effect |
|---|---|---|
| `workflow.rules` | Pipeline creation | GitLab admits merge request events and pushes to the default branch. With no matching rule, the pipeline is excluded. An MR pipeline still depends on the project's permissions and event context. |
| `stages` and each `stage` | Graph construction | The producer appears in `prepare` and the consumer in `test`. |
| `default.tags` | Runner assignment | Both jobs require a runner with `windows-rust`. Scope, protection and available capacity still apply. |
| Producer `script` | PowerShell execution | The job writes its commit identity to a file in the working directory. |
| Producer `artifacts` | After the producer script | Runner uploads the marker. The configured expiry is one day, subject to GitLab retention settings such as keeping artifacts from the latest successful pipeline. |
| Consumer `needs` | Scheduling and artifact transfer | The consumer waits for the producer and downloads its artifact before the script. Moving these jobs onto different eligible hosts preserves the transfer. |
| Consumer `script` | PowerShell execution | The job checks the marker against its own commit and runs the tests with the locked dependency graph. A mismatch or failed Cargo command fails the job. |

See the [GitLab YAML reference](https://docs.gitlab.com/ci/yaml/) for keyword syntax and [runner configuration](https://docs.gitlab.com/ci/runners/configure_runners/) for eligibility.

## Simulated pipeline record

| Field | Value |
|---|---|
| Pipeline and source | 840, `push` |
| Ref and commit | `main`, `a1b2c3d` (abbreviated) |
| Graph | `record_revision` #410 → `test_rust` #411 |
| Consumer assignment | `win-rust-02`, Shell executor, PowerShell Core |
| Consumer trace in order | Checkout → download artifact from #410 → compare commit marker → run Cargo → cleanup → success |

In an existing project, correlate these fields by opening **Build → Pipelines**, filtering by source and ref, then opening the pipeline graph and job log. Use the dependency graph view where available to distinguish explicit dependencies from stage layout. The same commit can have multiple pipelines, so record the pipeline ID and job ID. Record runner details visible in the job or trace, with unavailable fields marked unknown. [Pipeline graph](https://docs.gitlab.com/ci/pipelines/), [job logs](https://docs.gitlab.com/ci/jobs/job_logs/)

## Exercises and worked answers

1. **Predict the graph.** Compare a push to `feature/demo`, a merge request event for that branch, a push to `main`, and a schedule on `main`.  
   **Answer** — The MR event and default-branch push create both jobs under the stated assumptions. The feature-branch push and schedule match neither rule. A missing pipeline is a server-side admission question.
2. **Diagnose a pending consumer.** #410 passed, #411 is pending and has no runner trace. The only runner that is accepting jobs now has `linux-rust`.  
   **Answer** — The graph admitted the consumer, but the active runner cannot satisfy `windows-rust`. Compare tags, scope, protection and capacity. Restore the intended Windows runner or review the job's routing configuration. Removing the tag could route the job to an incompatible host.
3. **Diagnose a failed consumer.** #411 shows a successful checkout, then reports that the producer artifact could not be retrieved. There is no Cargo output.  
   **Answer** — Assignment and checkout succeeded. Check the producer job ID, artifact upload and retention. Recovery evidence is a successful download of the marker for the intended commit followed by Cargo output.
4. **Review a proposed edit.** A teammate wants to set `artifacts: false` in the consumer's `needs` entry.  
   **Answer** — The ordering edge survives, but the marker transfer is disabled. In a clean workspace the marker is absent. A leftover file on a persistent host is also invalid evidence of a successful transfer.

## Acceptance

From the example, identify the event, ref, commit, graph edge, runner, executor, shell and last successful boundary for each incident. Explain how a missing pipeline, pending job, failed checkout and failed artifact download differ, and predict the effect of the proposed YAML edit. Use the worked answers to score the exercise. Runtime practice is listed in [Future labs](../../FUTURE-LABS.md).
