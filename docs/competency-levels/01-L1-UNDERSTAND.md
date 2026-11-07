# L1 · Understand

Given an existing configuration, explain what happens, why it happens and which component owns the decision. Produce a short annotated graph with an event, ref, commit, job selection, runner boundary and output. The input is a configuration and a record of assumptions. All examples and traces here are illustrative and unexecuted. The [competency model](00-COMPETENCY-MODEL.md) introduces Ledger Gateway, the enterprise workspace used throughout the module.

## Read from the event to the shell

Start with the event and the configuration revision. GitLab resolves included configuration, evaluates workflow and job rules, and forms a graph. Stages provide default ordering. Explicit dependency edges can change when a job becomes eligible and which producer artifacts it downloads. A runner requests work and GitLab assigns an eligible job. The executor controls how the runtime is prepared. With the Shell executor, the job executes directly on the runner host using its configured shell and the runner process identity.

Follow the job in execution order. The runner prepares sources, restores a configured cache, downloads selected artifacts and starts the shell commands. Finalization can include a separate shell for `after_script`, cache and artifact uploads, and cleanup. Some operations are conditional and their trace sections may be absent. Treat a missing pipeline, a queued job and a failed shell command as three different places to start reading. [GitLab job execution flow](https://docs.gitlab.com/ci/jobs/job_execution/)

## Annotate the three configuration layers

This Ledger Gateway excerpt assumes a producer called `prepare` in an earlier stage publishes `build-commit.txt`. The selected Windows runner is assigned to the project.

```yaml
test_windows:
  stage: test
  tags: [windows-rust]
  needs:
    - job: prepare
      artifacts: true
  script:
    - Get-Content -LiteralPath build-commit.txt
    - cargo test --workspace --locked
```

`stage` classifies the job. `needs` gives an explicit dependency and requests the producer's artifact. The first command reads a marker, while the second runs tests in the resolved Cargo workspace. This excerpt prints a commit identifier. A release pipeline that uses the marker as proof must compare it with the expected revision. The tag is an eligibility requirement. The tag's name alone says nothing about what is installed on the host. [GitLab YAML reference](https://docs.gitlab.com/ci/yaml/)

```toml
# Excerpt from runner config.toml
[[runners]]
  name = "ledger-windows"
  executor = "shell"
  shell = "pwsh"
```

This excerpt explains why the YAML uses PowerShell commands and why the service identity's executable search path matters. The runner name helps correlate evidence. GitLab-side assignment, tags and protection are separate settings. Record whether the shell is PowerShell Core or Windows PowerShell when reading scripts that may depend on language or native command behavior. [Runner shells](https://docs.gitlab.com/runner/shells/)

```toml
# Excerpt from the workspace Cargo.toml
[workspace]
members = ["crates/ledger-core", "crates/gateway"]
resolver = "2"
```

Cargo finds the workspace members through the manifest. The resolver setting influences dependency feature resolution. `Cargo.lock` records resolved versions and sources, while `--locked` requires an existing resolution that Cargo can use without modifying that file. A Maven parent POM and reactor provide a useful analogy for a shared build, but dependency mediation, feature selection and lockfile behavior require Cargo-specific reasoning. A Rust `Result` also makes typed failures visible in signatures where Java code might propagate an exception. [Cargo workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html), [cargo test](https://doc.rust-lang.org/cargo/commands/cargo-test.html)

## Read settings and policy inputs

Identify variable definitions before reasoning about their effective values. A project setting can outrank a YAML job variable. Protected and environment-scoped values have eligibility conditions before precedence matters. A file variable provides a path to a temporary file. Masking limits supported log output, so record scope and presence without recording values. The role required to change a setting can differ from the access needed to read a job trace. [GitLab variables](https://docs.gitlab.com/ci/variables/)

A Cargo cache supplies reusable input. The artifact in the example is tied to a producer job and consumed through an explicit edge. For release evidence, ask which revision generated the report and which policy owner interpreted it. SonarQube can evaluate quality from analysis and imported coverage. Nexus IQ evaluates dependency policy through a supported input path. Fortify provides static security evidence where the installed Rust scan mode supports it. Verify the supported capability before inferring that an uploaded report covers Rust. [Version and support references](../concepts/README.md)

## Reading exercises

### 1 · Explain a queued job

An MR pipeline includes `test_windows`. Its producer succeeded. The job is pending, and the only runner online is tagged `linux-rust`. Which component owns this boundary and which commands have run for the pending job?

**Expected answer** — GitLab created the job and the producer satisfied the dependency. The listed runner does not meet the tag requirement. The pending job has no runner execution, so none of its checkout or Cargo commands has run. An actual eligibility review also checks scope, protected refs and capacity.

### 2 · Explain a missing marker

The job moved to a second host. It restored a Cargo cache and then failed to download the producer artifact. Explain which input was restored, what GitLab record identifies the intended producer, and whether the test ran.

**Expected answer** — The cache restore establishes reuse of a cache archive. The pipeline edge and producer job identity identify the marker source. A failed artifact download stops the normal main-script path. Inspect the upload record, artifact retention and the dependency mapping before changing Cargo.

### 3 · Explain the effective variable

YAML sets `SCAN_MODE=observe`. An eligible project variable sets `SCAN_MODE=enforce`. A separate protected file variable supplies a scanner credential path. Assume no higher-priority override and an unprotected branch without special MR access.

**Expected answer** — The eligible project value wins. The protected credential is unavailable in this context. If made eligible by the intended trust policy, its shell value would be a file path. The scanner integration must handle the missing credential without logging sensitive content.

## Acceptance

Answer all three exercises and identify the responsible component, decisive evidence and resulting behavior in each. Annotate all three configuration excerpts and explain the difference between a Maven reactor build and a GitLab job dependency. Mark any missing context explicitly. Use the [assessment rubric](04-SUMMARY-VALIDATION.md) before moving to [L2](02-L2-MODIFY.md).
