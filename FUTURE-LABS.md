# Future labs

Every lab below is **PLANNED / NOT EXECUTED**. Implementation and runtime verification are deferred until explicitly requested. These exercises are independent of documentation completion.

## P0 · GitLab execution lifecycle

**Status** — PLANNED / NOT EXECUTED.

- **Objective** — Trace a sandbox job.
- **Infrastructure and permissions** — Read access to a pipeline graph, job logs and runner details available to the learner.
- **Configuration steps** — Select an existing sandbox pipeline with a completed job. Open Build → Pipelines, choose the job and expand its trace sections.
- **Expected behavior** — Explain where a pending job stops and where a failed checkout stops.
- **Verification** — Open a supplied pipeline and inspect its ref, source, graph, runner and trace; identify which component owns each transition.
- **Common failures** — Missing logs or runner details, a pending job, or a checkout authentication error.

## P1 · Rust for Java developers

**Status** — PLANNED / NOT EXECUTED.

- **Objective** — Build a small library and CLI; Diagnose ownership and API choices.
- **Infrastructure and permissions** — A disposable local folder and Rust toolchain. Registry access if a dependency is needed.
- **Configuration steps** — Create a disposable crate and add parsing tests. Introduce a move-after-use error and repair it with borrowing.
- **Expected behavior** — Explain which component owns each input and why the repair does not require cloning.
- **Verification** — Use cargo new after review; run cargo check and cargo test. Tests cover successful parsing and a typed error. Introduce a move-after-use error, read the compiler diagnostic, then repair it using a borrow. Run cargo fmt --check and cargo clippy --all-targets -- -D warnings.
- **Common failures** — Move-after-use errors, format drift or a failing parser test.

## P2 · Cargo builds and dependency management

**Status** — PLANNED / NOT EXECUTED.

- **Objective** — Inspect and lock the dependency graph; Build and package a workspace member.
- **Infrastructure and permissions** — Rust and Cargo, write access to a disposable workspace and approved registry read access.
- **Configuration steps** — Create a sandbox workspace with pinned dependencies and a committed lockfile. Configure the approved registry if needed.
- **Expected behavior** — Explain a stale lockfile error and distinguish the release executable from the crate package.
- **Verification** — Use cargo metadata --locked --format-version 1 and cargo tree -e features. Record the selected workspace members and feature path. Run cargo test --workspace --locked, cargo build --release --locked and cargo package --list -p <crate>. Identify release binary and crate contents; rehearse an isolated packaging check before any publishing.
- **Common failures** — Stale lockfile, unexpected feature activation or registry authentication failure.

## P3 · GitLab CI YAML from zero

**Status** — PLANNED / NOT EXECUTED.

- **Objective** — Author and lint a minimal sandbox pipeline; Validate rules, reuse and graph behavior.
- **Infrastructure and permissions** — Sandbox branch write access, CI Lint access and permission to use included templates and eligible runners.
- **Configuration steps** — Add a one-job pipeline, then introduce stages, workflow rules, an explicit dependency and a pinned include.
- **Expected behavior** — Explain why a YAML parser can accept a configuration that CI Lint rejects and why a lint simulation cannot cover every source.
- **Verification** — Start with one script job, then add stages and a second job. CI Lint must accept both revisions; the graph must show stage ordering. Add workflow rules, a pinned include and a reused job. Inspect merged YAML and exercise push, MR, schedule and manual pipeline cases in a sandbox; compare expected jobs and duplicate suppression.
- **Common failures** — Invalid YAML, missing include, duplicate pipelines or an unsatisfied dependency.

## P4 · Variables, roles and secret boundaries

**Status** — PLANNED / NOT EXECUTED.

- **Objective** — Demonstrate precedence using synthetic values; Exercise scope and protection.
- **Infrastructure and permissions** — Project Maintainer, group Owner for group variables, and authorized protected-ref access. Verify the instance rules.
- **Configuration steps** — Create synthetic group, project, protected, scoped and file variables. Use a harmless presence probe on protected and unprotected refs.
- **Expected behavior** — Produce a precedence table and prove secret presence follows the intended trust boundary.
- **Verification** — Set the same harmless key in group, project and YAML, then optionally supply a pipeline value if authorized. Print only this key and compare the winner with the instance documentation. Use dummy protected and file variables, a matching environment and two ref types. Log presence and type only, and record which roles can access each settings surface.
- **Common failures** — Unexpected override, ref protection mismatch or a file path treated as a secret value.

## P5 · Cache, artifacts and reuse

**Status** — PLANNED / NOT EXECUTED.

- **Objective** — Measure cold, warm and stale Cargo caches; Prove producer-to-consumer artifact transfer.
- **Infrastructure and permissions** — Sandbox branch write access, an eligible runner and access to producer artifacts. Backend changes require the runner operator.
- **Configuration steps** — Configure a project-relative Cargo cache and commit-stamped producer artifact. Set up an explicit consumer dependency.
- **Expected behavior** — The consumer receives the expected commit marker even with an empty cache.
- **Verification** — Run with a unique key, repeat on the same backend, then deliberately reuse a static key across a harmless fixture schema change. Record restore status and timings; key by lockfile and platform/toolchain to invalidate. Pass a commit-stamped file through needs with artifacts enabled, then rehearse expired/missing artifacts. Plan parent-child or cross-project retrieval with provenance and tier checks.
- **Common failures** — Different cache backend, stale key or expired producer artifact.

## P6 · Windows Shell runner

**Status** — PLANNED / NOT EXECUTED.

- **Objective** — Register a dedicated project runner; Run the service-context toolchain probe.
- **Infrastructure and permissions** — Dedicated Windows VM, Windows administration for service installation, project Maintainer for runner creation and a permitted service identity.
- **Configuration steps** — Register a project runner using the authentication-token workflow on the lab VM. Configure the Shell executor, PowerShell Core and service identity.
- **Expected behavior** — Record account, explicit shell, matching tags, toolchain, protected-ref behavior and the isolation decision.
- **Verification** — Create it with a runner authentication token; register on the VM using the shell executor. Install/start the service, then verify connectivity, service state and server-side eligibility. Use a tagged job to check whoami, Get-Command git,cargo,rustc,pwsh and rustc -vV. Reproduce a missing service PATH entry, fix the service environment and rerun. Verify a native compile.
- **Common failures** — Service account logon, PATH, protected-tag mismatch, TLS or MSVC linker failure.

## P7 · GitHub Actions migration

**Status** — PLANNED / NOT EXECUTED.

- **Objective** — Inventory the source workflow and define parity; Migrate and compare execution.
- **Infrastructure and permissions** — GitHub and GitLab sandbox write and workflow-run permissions, with equivalent runners and artifact access.
- **Configuration steps** — Set up equivalent sandbox workflows and toolchains. Configure matching events, cache inputs and artifact transfers.
- **Expected behavior** — Account for each event, shell, permission and artifact difference with observed or explicitly unavailable evidence.
- **Verification** — Read a supplied Rust workflow and record trigger, runner OS, tools, cache keys, test commands and outputs. Predict outcomes for push, PR, fork and manual dispatch. Create a GitLab sandbox equivalent after review. Validate merged config and run the parity matrix; compare cargo test --locked output, cache warmup and artifact content.
- **Common failures** — Event duplication, fork permissions, shell differences or missing artifacts.

## P8 · SonarQube quality and coverage

**Status** — PLANNED / NOT EXECUTED.

- **Objective** — Produce Rust coverage on the target runner; Run analysis and test enforcement.
- **Infrastructure and permissions** — Compatible scanner and server, Rust coverage tools, permission to analyze the Sonar project and a server-side gate owner.
- **Configuration steps** — Set up a SonarQube test project, install compatible tools and pass generated LCOV to the scanner. Configure quality gate waiting.
- **Expected behavior** — Prove the analyzed commit, imported coverage and quality gate decision agree.
- **Verification** — Verify a pinned coverage producer against its help and official docs. Generate LCOV for the tested commit and confirm source paths and nonzero covered lines. Check target server Rust support and scanner version; run SonarScanner with the documented Rust LCOV property and gate wait. Capture the task ID and observed pass, gate failure and timeout outcomes.
- **Common failures** — Coverage path mismatch, missing analyzer prerequisite or gate timeout.

## P9 · Nexus IQ dependency policy

**Status** — PLANNED / NOT EXECUTED.

- **Objective** — Prove Cargo matching against a supported IQ environment; Exercise warn, fail and scanner error outcomes.
- **Infrastructure and permissions** — Licensed Lifecycle test instance, compatible CLI and an application-scoped identity allowed to submit evaluations.
- **Configuration steps** — Set up a test Lifecycle application and policy stage, then evaluate a controlled Cargo.lock with the supported CLI.
- **Expected behavior** — Correlate a decision with an actual component and policy or label it as simulated.
- **Verification** — Confirm CLI/server compatibility, Rust support and the required application role. Evaluate a controlled Cargo.lock with the documented CLI and verify resolved coordinates in the report. Use authorized sandbox policies or labeled fixtures. Record application, stage, policy action and exit behavior; distinguish no matches, a policy violation and transport failure.
- **Common failures** — Unsupported Cargo matching, incorrect application ID, transport failure or policy block.

## P10 · Fortify static security analysis

**Status** — PLANNED / NOT EXECUTED.

- **Objective** — .
- **Infrastructure and permissions** — Licensed Rust-capable SAST environment, approved source handling and permission to submit and review results.
- **Configuration steps** — Configure an approved Rust-capable OpenText scan mode and test destination. Scan a controlled source fixture and apply the sandbox policy.
- **Expected behavior** — Explain whether each result proves Rust coverage, report upload or policy evaluation.
- **Verification** — Record product/version, AI-powered SAST entitlement, execution path and source data boundary. In an approved lab, confirm source enumeration and scan mode in vendor logs. Use a controlled finding and approved integration to check report ingestion, severity and gate result. With no licensed environment, use labeled pass/block/error fixtures and capture the gate evidence.
- **Common failures** — Wrong scan mode, failed upload or missing policy evidence.

## P11 · End-to-end enterprise pipeline

**Status** — PLANNED / NOT EXECUTED.

- **Objective** — .
- **Infrastructure and permissions** — Sandbox CI write access, Windows runner and all approved vendor environments. Coordinate protected ref and credential changes with their owners.
- **Configuration steps** — Connect the approved Windows jobs, reports and three gates with explicit dependencies and restrict credentials to trusted refs.
- **Expected behavior** — Record each gate's evidence and live/simulated status. Require live checks for live sign-off.
- **Verification** — Integrate approved jobs and reports via pinned templates and explicit needs. Lint merged YAML and compare MR versus protected default-branch topology. Check passing, blocked and unavailable scanner paths, plus fork behavior. Verify packaged artifacts are traceable to the tested commit and blocked when an enforced gate fails.
- **Common failures** — Artifact provenance mismatch, scanner outage or privileged job exposed to an untrusted ref.

## P12 · Enterprise troubleshooting

**Status** — PLANNED / NOT EXECUTED.

- **Objective** — .
- **Infrastructure and permissions** — Disposable sandbox with Windows runner, access to traces and delegated fault-injection permissions. Approved vendor access for scanner outages.
- **Configuration steps** — Inject isolated scheduling, environment, certificate, artifact and scanner faults in a disposable project.
- **Expected behavior** — Supply a hypothesis, discriminating check, remediation and proof of recovery for each drill.
- **Verification** — Reproduce a sandbox tag mismatch and service PATH failure. Compare job status, runner status, Event Viewer and Get-Command before and after a scoped repair. Use sandbox faults or sanitized traces for TLS/proxy, stale cache, expired artifact, authorization and scanner timeout. Probe the failing endpoint under the service identity and document recovery.
- **Common failures** — Misclassifying a server, host, network or policy failure and applying a fix at the wrong boundary.

## P13 · Enterprise readiness assessment

**Status** — PLANNED / NOT EXECUTED.

- **Objective** — .
- **Infrastructure and permissions** — Sandbox write and run permissions, Windows runner and access to evidence. Vendor access is required for live gate sign-off.
- **Configuration steps** — Prepare an incident and a bounded change in a dedicated sandbox with a known-good baseline and rollback target.
- **Expected behavior** — Meet the rubric and explain the next step for every unmet live prerequisite.
- **Verification** — Diagnose one hidden failure in a sanitized existing pipeline and give a safe mitigation, an owner and a verification step. Modify a sandbox pipeline, run lint and two execution scenarios, and provide a rollback plan. Score with the assessment rubric and note live/simulation coverage.
- **Common failures** — Insufficient recovery evidence, weakened controls or unverified rollback.
