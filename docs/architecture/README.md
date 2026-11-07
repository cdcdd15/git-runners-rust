# Pipeline and job execution

GitLab evaluates included configuration, workflow and job rules to create a pipeline. A pipeline groups jobs for a ref and event. Stages supply default barriers. A job with a `needs` graph can start once its listed prerequisites are satisfied. Runner is the agent that requests work. Its executor prepares the runtime, its shell interprets generated commands and the script contains the work to run.

```mermaid
flowchart LR
  Push[Git push or other event] --> Server[GitLab server]
  Server --> Pipeline[Pipeline and job graph]
  Pipeline --> Queue[Eligible queued jobs]
  Runner[GitLab Runner service] <-->|Request and assignment| Queue
  Runner --> Executor[Shell executor]
  Executor --> PS[PowerShell process]
  PS --> Cargo[Cargo and approved scanners]
  Runner --> Cache[Local or distributed cache]
  Runner --> Server
```

```mermaid
sequenceDiagram
  participant D as Developer
  participant G as GitLab
  participant R as Runner
  participant S as Executor and shell
  D->>G: Push commit
  G->>G: Resolve config and evaluate rules
  R->>G: Request an eligible job
  G-->>R: Assign job and job credentials
  R->>S: Prepare executor and obtain sources
  R->>S: Restore cache then download configured artifacts
  R->>S: Execute before_script and script
  R->>S: Execute after_script in a fresh shell when applicable
  R->>R: Upload configured cache to its backend
  R->>G: Upload configured artifacts and send trace
  R->>S: Clean up job files and temporary secrets
  R->>G: Report final result
```

Runner polls GitLab, potentially using long polling. Tags, scope, protected-ref eligibility and capacity affect assignment. The runner prepares the executor and handles external secrets if configured. Cache and artifact operations depend on job configuration and earlier step outcomes. Cache upload occurs before artifact upload. Cleanup includes removal of temporary file variables. A Shell executor shares the host and its service identity across jobs, so separate trust boundaries at the VM or runner pool. See [GitLab job execution](https://docs.gitlab.com/ci/jobs/job_execution/) and [Shell executor](https://docs.gitlab.com/runner/executors/shell/).
