# P0.1 · Annotate a GitLab job trace

**Access** — Local. Allow 25–35 minutes. Read the [lifecycle chapter](../concepts/job-lifecycle.md) and [trace reference](../references/job-trace-reference.md) before annotating the fixture.

The fixture is a simulation of a successful job on a Windows Shell runner using PowerShell Core. Line numbers and messages are instructional. Real trace headings vary by runner version and job configuration.

## Input

The push created a pipeline with a `test` job. The job is eligible for a dedicated Windows runner and consumes an artifact from the earlier `prepare` job. It restores and updates a Cargo dependency cache, publishes a summary and uses a temporary file variable. The pipeline graph and pending time are outside the excerpt.

```text
01  Preparing Shell executor (pwsh) on win-lab-01
02  Fetching sources and checking out a1b2c3d
03  Restoring cache cargo-win-msvc-lab: archive extracted
04  Downloading artifacts for prepare (job 410): build-info.txt
05  Running before_script: cargo --version
06  Running script: cargo test --locked
07  test result: ok. 2 passed; 0 failed
08  Running after_script in a fresh shell: write summary.txt
09  Saving updated cargo-win-msvc-lab cache
10  Uploading summary.txt as job artifact
11  Cleaning up temporary file variables
12  Job succeeded
```

## Exercise

1. Before checking the answer, label each line with its execution phase and owner. Distinguish the component arranging the work from the process running a command.
2. Mark the first point where Cargo can run, the producer of each downloaded input, and the point where the test summary becomes available to another job.
3. Compare the labels with the [architecture sequence diagram](../architecture/README.md) and the [official job execution flow](https://docs.gitlab.com/ci/jobs/job_execution/). Record any differences in scope. For example, the official sequence also covers optional hooks and referee data.
4. For each variant below, name the last successful boundary and the first check you would make.

   - The job remains pending and has no runner execution trace.
   - Line 02 fails with a Git authentication error.
   - Line 03 reports a cache miss, and execution continues.

## Verified annotation

| Lines | Phase and owner | Evidence |
|---|---|---|
| 01 | Runner prepares the Shell executor | The job was assigned and the executor will use PowerShell Core on the Windows host. |
| 02 | Runner source preparation invokes Git | The working tree is prepared for commit `a1b2c3d`. |
| 03 | Runner restores its configured cache | An archive from the cache backend was extracted. A hit alone does not establish provenance or freshness. |
| 04 | Runner downloads a producer job's artifact | The trace identifies `prepare` and job 410 as the source of `build-info.txt`. |
| 05–07 | PowerShell executes the job commands; Cargo runs the tests | Cargo starts in `before_script`. The test result comes from Cargo. |
| 08 | Runner invokes `after_script` in a new shell | The shell writes `summary.txt`. Files can carry state between these steps. Shell-local state from the main script is lost. |
| 09–10 | Runner saves the cache, then publishes the artifact | The summary becomes available for configured downstream artifact download after publication. |
| 11–12 | Runner performs cleanup and reports status | The temporary file variable is removed and the job ends successfully. |

GitLab evaluated configuration and queued the job before line 01. A runner requested and received the job before it prepared the executor. Maven's lifecycle is closer to the ordered work inside a build invocation. GitLab owns pipeline scheduling and Runner orchestrates the work around Cargo.

**Variant results**

- **Pending** — GitLab queued the job. Check runner eligibility and capacity, including scope, tags, protected-ref settings and available slots.
- **Checkout authentication failure** — The runner started the job and reached source preparation. Check which repository operation failed and which credential it used. The normal restore, artifact download and main-script path will be skipped after failed source preparation. Configured finalization may still run.
- **Cache miss** — Checkout succeeded and the runner attempted a restore. If later commands succeed, the job can complete cold. Compare the computed key and backend with the producer run when investigating repeated misses.

## Acceptance

Correctly place checkout, cache restore, artifact download, main script, cache and artifact upload, and cleanup. Explain the difference between pending and checkout failure, and identify what proves the summary was published. The table above records the observed ordering in the simulated fixture. Use the [P0 scoring crosswalk](../roadmap/P0.md#p0-scoring-crosswalk) for offline validation. Live trace verification is tracked in [Future labs](../../FUTURE-LABS.md).
