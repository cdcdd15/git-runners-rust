# P0.03 · Enterprise architecture and operational boundaries

## 4. Configuration and enterprise boundaries

| Surface | Owns |
|---|---|
| GitLab project or group settings | Runner scope and routing controls, ref protection, variable policies and permissions. |
| `.gitlab-ci.yml` and includes | Pipeline admission, job selection, dependencies, commands and transfer declarations. |
| Runner configuration and host | Executor, shell, concurrency, work directories, cache backend and service identity. |
| Cargo files and tooling | Workspace, dependency resolution and build behavior inside the job. |

A Maven lifecycle orders phases inside a build invocation. GitLab stages and dependencies coordinate separate jobs that can run on different hosts. A successful Maven or Cargo command cannot carry a local build output into a later job by itself. Declare the transfer and verify the consumer's expected producer. For deeper coverage see [P3 configuration](../../roadmap/P3.md), [P5 storage](../../roadmap/P5.md) and [P6 runner architecture](../../roadmap/P6.md).

## 5. Selected illustrations

**Illustrative and unexecuted.** A protected branch push creates a build job and a verification job. Runner checks out commit A, misses its Cargo registry cache, builds successfully and uploads an executable with a commit marker. A second runner downloads that artifact and verifies the marker. The cache miss changes the build cost. The explicit transfer preserves the handoff between the two hosts.

In an alternate run, the build job is pending and its required Windows tag is absent from every available runner. There is no checkout or Cargo output to diagnose. If a runner later accepts the job and reports a checkout authentication failure, the fault boundary has moved. Inspect the source endpoint and authorized checkout credentials before changing build commands. For annotated practice see [P0.1](../../labs/p0-1-job-trace.md) and [P0.2](../../labs/p0-2-pipeline-walkthrough.md).

## 6. Synthesis and knowledge checks

The event and effective configuration explain which jobs exist. The dependency graph and runner eligibility explain when and where they can start. Runner's trace identifies what executed and the first failing operation. A published artifact requires separate evidence of producer and transfer. This ordering lets an operator narrow a failure without searching every system or exposing unrelated credentials.

1. **A merge request shows no test job. Which evidence comes first?** Check the pipeline source and effective job rules before checking runner tags. Tags matter only after GitLab includes the job.
2. **A producer is green but its consumer has no executable. What would distinguish a transfer problem from a build problem?** Verify the producer's upload record, job ID, artifact paths and the consumer's transfer declaration. Check the consumer's trace for retrieval.
3. **The main script sets a shell variable and writes a file. Which can an applicable `after_script` use?** The new shell can read the workspace file. It cannot depend on the earlier shell's local variable.

Previous: [Components and flows](02-components-and-flows.md). Apply the model with the [job trace reference](../../references/job-trace-reference.md) and [scored exercises](../../roadmap/P0.md#p0-scoring-crosswalk).
