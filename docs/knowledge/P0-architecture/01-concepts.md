# P0.01 · GitLab job lifecycle concepts

## 1. Concepts and definitions

A **repository** stores the source and its history. A **commit** identifies a snapshot of that history. A **ref** names a branch, tag or other reference to a commit. A **pipeline source** identifies how GitLab was asked to create a pipeline, such as a push, merge request or schedule. Record the source, ref and commit when comparing runs. Two pipelines can examine the same commit and have different jobs because their sources differ.

A **pipeline** coordinates work for an event. A **job** is a unit of work with its own state and trace. A **stage** groups jobs and provides default ordering. A **dependency graph** expresses more specific prerequisites, allowing a job to become eligible without waiting for every unrelated job in an earlier stage. Explicit dependencies can also control which artifacts a consumer receives. GitLab constructs and schedules the graph. The build commands inside a job do not construct it after execution begins. [GitLab pipelines](https://docs.gitlab.com/ci/pipelines/), [GitLab YAML reference](https://docs.gitlab.com/ci/yaml/)

A **runner record** is GitLab's server-side representation of a runner, including its scope and routing settings. A **runner manager** is the running agent that requests work. An **executor** prepares the execution environment for an assigned job. A **shell** interprets the generated script, which wraps the repository's commands with runner-managed steps. For a Windows Shell job, that environment uses installed host tools and the runner service's identity. A container executor provides a different execution environment. A job tag helps match a runner and does not install tooling or select an executor by itself. [Runner scopes](https://docs.gitlab.com/ci/runners/runners_scope/), [executors](https://docs.gitlab.com/runner/executors/)

A **workspace** is where the assigned job checks out and processes files. A **cache** reuses selected files by key, such as Cargo registry inputs. An **artifact** is a job output published through GitLab, such as a test report or executable. Cache availability may vary by runner and storage configuration. Artifact retrieval depends on the selected producer, access and retention. [GitLab caching](https://docs.gitlab.com/ci/caching/), [job artifacts](https://docs.gitlab.com/ci/jobs/job_artifacts/)

Next: [Components and flows](02-components-and-flows.md).
