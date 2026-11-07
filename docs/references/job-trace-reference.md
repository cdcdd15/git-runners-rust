# GitLab job trace reference · P0.B

Use this reference after the [job lifecycle chapter](../concepts/job-lifecycle.md). It shows how to correlate effective configuration, a job graph and a runner trace before deciding which team owns a failure. All configuration and trace records below are illustrative and unexecuted.

## Complete configuration · Push and merge request checks

This variant of the [P0.2 pipeline](../labs/p0-2-pipeline-walkthrough.md) adds an independent formatting check to illustrate the difference between stage order and an explicit dependency. Assume an eligible Windows Shell runner using PowerShell Core, with Cargo and rustfmt available under its service identity. Both admitted event types use the same job graph. The example has no cache policy.

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
    - Set-Content -LiteralPath build-commit.txt -Value $env:CI_COMMIT_SHA -ErrorAction Stop
  artifacts:
    paths: [build-commit.txt]
    expire_in: 1 day

check_format:
  stage: prepare
  script:
    - cargo fmt --all -- --check

test_rust:
  stage: test
  needs:
    - job: record_revision
      artifacts: true
  script:
    - |
      $revision = (Get-Content -LiteralPath build-commit.txt -Raw -ErrorAction Stop).Trim()
      if ($revision -cne $env:CI_COMMIT_SHA) {
        throw "Producer marker does not match the test commit"
      }
      cargo test --workspace --locked
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

| Configuration | Decision and consequence |
|---|---|
| `workflow.rules` | GitLab admits MR events and default-branch pushes. A feature-branch push with no MR event, a schedule and a tag push do not match. |
| `stages` and job `stage` | Without explicit dependencies, the later test stage would normally wait for both jobs in the prepare stage. |
| `default.tags` | Each job requires an eligible runner tagged `windows-rust`. Tags do not specify PowerShell or provide tools. Runner scope, ref protection and capacity still affect assignment. |
| `record_revision` and `artifacts` | The producer writes the assigned commit and publishes the marker on success. Retention settings can affect how long it remains available beyond the configured expiry. |
| `test_rust.needs` | Tests can become eligible once `record_revision` succeeds, even while formatting is running. The edge requests the marker from that producer. A formatting failure still affects overall pipeline status. |
| Test `script` | PowerShell reads the downloaded file, compares it with the current job commit, and propagates Cargo failure. In an MR context compare against the actual pipeline checkout SHA, not an assumed branch tip. The marker checks revision agreement under the assumed trust in the producer. |

If formatting must pass **before** tests start, add `check_format` as a second `needs` entry with `artifacts: false`. Keep the existing producer edge. This introduces an ordering dependency without transferring formatting outputs. Removing the producer's artifact transfer instead would preserve the wait but leave the consumer without its marker on a clean checkout. [GitLab workflow rules](https://docs.gitlab.com/ci/yaml/workflow/), [GitLab needs](https://docs.gitlab.com/ci/yaml/#needs), [artifact retention](https://docs.gitlab.com/ci/jobs/job_artifacts/)

## Correlate the record before reading commands

In **Build → Pipelines**, identify the project, pipeline ID, source, ref and commit. Open the job graph to locate the producer and consumer, then record the job IDs and runner identity visible in the job details or trace. This matters when the same commit has both a push and an MR pipeline, or when a retry has another job ID. The table uses abbreviated, synthetic commits.

| Pipeline | Source and ref | Commit | Job records |
|---|---|---|---|
| 840 | `push` on default branch `main` | `a1b2c3d` | `record_revision` #410, `check_format` #412, `test_rust` #411 |
| 841 | `merge_request_event` for MR !18 | `b2c3d4e` | `record_revision` #413, `check_format` #415, `test_rust` #414 |

### Annotated trace · Pipeline 840, consumer #411, commit a1b2c3d

These records summarize what an operator can observe. They are not literal GitLab log lines.

| Order | Observed record | Responsible component and interpretation |
|---:|---|---|
| 1 | Pipeline 840 contains both prepare jobs and the test job. | GitLab admitted a default-branch push and constructed the graph. |
| 2 | #410 publishes `build-commit.txt` and succeeds. #412 is still running. | The required producer has finished. GitLab can offer #411 without waiting for formatting. |
| 3 | #411 is assigned to `win-rust-02` using the Shell executor and PowerShell Core. | GitLab matched the job to an eligible runner, and Runner prepared its host execution environment. |
| 4 | Sources prepared for `a1b2c3d`. | Runner's source step establishes the checkout for this job. |
| 5 | No cache restore section. Artifact download identifies #410. | No cache was configured. Runner downloads the explicitly selected artifact before executing the test script. |
| 6 | Marker matches and Cargo reports passing tests. | The PowerShell and Cargo commands completed successfully. This does not establish the separate formatting result. |
| 7 | No configured `after_script` or consumer artifact upload. Cleanup completes and #411 is successful. | Optional steps can be absent. Check job status for #411 and overall pipeline status separately. |

For an example with cache restore, `after_script` and upload steps, compare the [P0.1 trace](../labs/p0-1-job-trace.md). Those steps depend on job configuration and outcome. [Pipeline graph](https://docs.gitlab.com/ci/pipelines/), [job logs](https://docs.gitlab.com/ci/jobs/job_logs/), [job execution order](https://docs.gitlab.com/ci/jobs/job_execution/)

## Choose the next check by boundary

| Evidence | Owner and scoped next check |
|---|---|
| No pipeline for a schedule on `main` | Configuration owner. Confirm the event source and first matching workflow rule. Add schedule admission only if scheduled execution is intended. |
| #414 is pending after #413 succeeds and no runner has the required tag | Runner operator. Confirm project scope, tags, ref eligibility and capacity. Restore a qualified runner or correct the routing contract. Removing the tag can broaden assignment. |
| #414 is assigned but checkout fails | Repository or runner operator. Identify the failing repository endpoint and checkout authorization. Cargo has not started. |
| Checkout succeeds but the download of #413 fails | Artifact producer or storage owner. Check #413's upload record, availability and access. Review the transfer edge before changing test commands. |
| Download succeeds but the marker differs | Producer or pipeline owner. Correlate pipeline, job and checkout commit, and investigate unexpected workspace files or the wrong input. Preserve the mismatch check. |

Use the documented configuration and trace together. A graph explains why a job should exist and what it waits for. The trace establishes how far that instance progressed. Apply the reference in [P0.1](../labs/p0-1-job-trace.md) and [P0.2](../labs/p0-2-pipeline-walkthrough.md).
