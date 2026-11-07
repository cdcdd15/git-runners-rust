# P3.2 · Review a reusable pipeline graph

**Access** — Offline. Allow 60–75 minutes. Start with [P3.1](p3-1-read-a-complete-gitlab-ci-file.md). The two configuration files, event inputs and graphs below are illustrative and unexecuted. Assume a GitLab version that supports typed include inputs, and a Windows Shell runner tagged `windows-rust` that uses PowerShell Core and has Cargo installed.

Ledger Gateway wants one shared Windows job template, no duplicate branch pipeline for a push to an open merge request, package tests for Rust changes in merge requests, and a diagnostic job for schedules and manually created pipelines. Work through four decisions in order. Resolve the includes, admit the pipeline, select the jobs, then validate their edges. Runner assignment occurs later. [GitLab includes](https://docs.gitlab.com/ci/yaml/includes/), [workflow](https://docs.gitlab.com/ci/yaml/workflow/), [job rules](https://docs.gitlab.com/ci/jobs/job_rules/)

## File 1 · Reusable template at ci/windows.yml

```yaml
spec:
  inputs:
    runner_tag:
      type: string
      default: windows-rust
---
.windows_rust:
  tags:
    - $[[ inputs.runner_tag ]]
  before_script:
    - rustc --version
  retry:
    max: 1
    when: runner_system_failure
```

The first YAML document declares an input to the template. The document separator precedes the job definitions. The input value is interpolated into configuration during pipeline creation. It supplies runner routing, and does not create a runtime variable. The leading dot makes `.windows_rust` a hidden job definition that can be extended. It creates no job of its own. [GitLab CI/CD inputs](https://docs.gitlab.com/ci/inputs/)

## File 2 · Root .gitlab-ci.yml

```yaml
include:
  - local: /ci/windows.yml
    inputs:
      runner_tag: windows-rust

workflow:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_PIPELINE_SOURCE == "push" && $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS'
      when: never
    - if: '$CI_PIPELINE_SOURCE == "push" && $CI_COMMIT_BRANCH'
    - if: '$CI_PIPELINE_SOURCE == "schedule" || $CI_PIPELINE_SOURCE == "web"'

stages: [verify, report]

default:
  before_script:
    - Write-Host "Starting job"

validate_lock:
  extends: .windows_rust
  stage: verify
  rules:
    - when: on_success
  script:
    - cargo metadata --locked --format-version 1

package_tests:
  extends: .windows_rust
  stage: verify
  parallel:
    matrix:
      - PACKAGE: [ledger-core, ledger-route]
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
      exists:
        - Cargo.toml
      changes:
        - Cargo.toml
        - Cargo.lock
        - crates/**/*
  script:
    - cargo test --locked -p $env:PACKAGE

diagnostics:
  extends: .windows_rust
  inherit:
    default: false
  stage: verify
  rules:
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
    - if: '$CI_PIPELINE_SOURCE == "web"'
      when: manual
      allow_failure: false
  script:
    - cargo --version

summary:
  extends: .windows_rust
  stage: report
  rules:
    - when: on_success
  needs:
    - job: validate_lock
      artifacts: false
    - job: package_tests
      optional: true
      artifacts: false
  script:
    - Write-Host "Selected validation jobs completed"
```

## Walk the merge and graph

1. The local include loads `ci/windows.yml` from the same ref. Substituting the supplied input yields `tags: [windows-rust]` on the hidden definition. Each visible job extends it and receives its tag, probe and retry policy. GitLab merges mapping keys when extending jobs. A child-provided array such as `before_script` replaces the parent array. The root default probe is unused here because the jobs already have a probe through `extends`. For `diagnostics`, `inherit:default: false` disables default inheritance. The probe from `extends` still applies.
2. Evaluate `workflow:rules` from top to bottom. The first match decides admission. The rule that rejects a branch push with an open MR must precede the general branch push rule. The push and branch checks keep the suppression scoped to branch pushes. Tags and unmatched sources fall through without admission.
3. In an admitted pipeline, the unconditional job rules add `validate_lock` and `summary` for every source. Jobs without rules are omitted from merge request pipelines by default, so the explicit rules keep the required edge valid in MR pipelines. For `package_tests`, the source, file existence and change predicates are all required because they share one rule. A match expands the package matrix into two job instances. Each gets one `PACKAGE` value. The schedule and web conditions select different behaviors for `diagnostics`.
4. `summary` waits for `validate_lock` and for all instances of `package_tests` when that matrix is present. It transfers no artifacts. The package-test edge is optional because some admitted events omit the job. A failed included package test still matters. `summary` can finish while a web pipeline waits on the separate blocking manual diagnostic job, since that job is outside its dependency graph.

A Maven parent POM offers a useful analogy for shared defaults. GitLab reuse also expands configuration before execution, but the resulting jobs are independently selected by an event and linked by scheduling edges. Review the merged configuration and the event graph separately.

## Worked event matrix

Read this matrix against the root configuration after resolving the include. Assume `Cargo.toml` exists unless stated otherwise.

| Event and ref | Pipeline admission | Included jobs and relevant behavior |
|---|---|---|
| Push to existing `feature/routing` with no open MR | Admitted by the branch-push rule | `validate_lock` → `summary` |
| Push to `feature/routing` with an open MR | Branch pipeline suppressed | Evaluate the separate MR event using the next rows |
| MR to `main` with edits under `crates/` | Admitted by the MR rule | `validate_lock` and both package tests can run in `verify`. `summary` waits for all three. |
| MR to `main` with a README-only change | Admitted by the MR rule | `validate_lock` → `summary`. The package tests are absent. |
| Scheduled pipeline on `main` | Admitted as `schedule` | `validate_lock` and automatic `diagnostics` are selected. `summary` waits only for `validate_lock`. |
| Run pipeline from the GitLab UI on `main` | Admitted as `web` | `validate_lock` → `summary`. The separate manual `diagnostics` job blocks overall completion until it is run. |
| Push tag `v0.1.0` | Excluded because `CI_COMMIT_BRANCH` is absent | No pipeline from this configuration |

An MR rule's change comparison uses the target branch. A branch-push comparison normally uses the previous commit. New branches and events without a push can produce matches without a diff unless an explicit comparison is configured. Keep the source guard or choose and review a `compare_to` baseline before sharing a change rule with scheduled or manual jobs. [GitLab YAML rules reference](https://docs.gitlab.com/ci/yaml/#ruleschanges)

## Keyword review card

Minimal forms are fragments at the stated scope. For target-instance validation when authorized, compare the expanded config in CI Lint with this manual walkthrough. Lint simulation alone does not establish the graph for each event.

| Keyword | Purpose and minimal form | Use and common error | Review check |
|---|---|---|---|
| `include` | Global import, such as `include: [{local: /ci/windows.yml}]`. | Local reuse here. Central templates can use `project` + `ref` + `file`, `remote` imports public URLs, `template` selects GitLab templates, and `component` selects catalog-style components. A floating ref can change the effective configuration. | For project includes verify access and pin an approved immutable ref. For remote includes review integrity controls and version support. Compare expanded jobs. |
| `spec:inputs` | File header schema, such as `spec: {inputs: {runner_tag: {type: string}}}` followed by `---` and the body. | `include:inputs` supplies the tag. An undefined or wrong-type input fails configuration. | Substitute the declared value and validate the type. |
| Hidden job | Top-level dot-prefixed mapping, such as `.windows_rust: {tags: [windows-rust]}`. | Reusable definition. Removing the dot can make it a visible job that needs executable configuration. | Count visible job names after merging. |
| `extends` | Job parent name or list, such as `extends: .windows_rust`. | Inherits the Windows settings. Lists replace instead of appending. | Compare effective arrays and mapping keys. |
| `inherit` | Job inheritance controls, such as `inherit: {default: false}`. | Disables defaults for diagnostics. It does not remove settings supplied by its parent. | Label each effective key as explicit, extended or defaulted. |
| `workflow:rules` | Pipeline admission, such as `workflow: {rules: [{if: '$CI_PIPELINE_SOURCE == "push"'}]}`. | Suppresses duplicate branch pipelines. A broad earlier rule can shadow the suppression. | Evaluate the first matching rule for each event. |
| Job `rules` and `if` | Job selection and attributes, such as `rules: [{if: '$CI_PIPELINE_SOURCE == "schedule"'}]`. | Selects diagnostic mode. Mistaking a shell condition for a GitLab expression changes evaluation. | Use GitLab variable syntax and trace first-match order. |
| `changes` | Paths within a rule, such as `changes: [Cargo.lock]`. | Selects package checks for Rust changes. A no-push event can unexpectedly match. | Name the event and comparison base. |
| `exists` | Repository paths within a rule, such as `exists: [Cargo.toml]`. | Restricts package tests to a workspace checkout. Generated job output is too late for this check. | Inspect the repository/ref at rule evaluation. |
| `when` | Job or matching-rule behavior, such as `when: manual`. | Makes web diagnostics manual and rejects branch pushes in workflow. | Distinguish pipeline source `web` from the manual state of an individual job. |
| `allow_failure` | Job or rule boolean, such as `allow_failure: false`. | Makes the manual diagnostic blocking. Defaults can differ for manual jobs declared inside and outside rules. | Check effective behavior instead of assuming all manual jobs are optional. |
| `needs` | Job DAG edges, such as `needs: [{job: validate_lock, artifacts: false}]`. | Keeps the summary gated on validation and any selected package tests. Required edges to omitted jobs invalidate a graph. | Remove the package tests in a paper simulation and review the remaining prerequisites. |
| `parallel:matrix` | Job variants, such as `parallel: {matrix: [{PACKAGE: [ledger-core, ledger-route]}]}`. | Tests each workspace package. A plain need on the matrix job waits on all its instances. | Expand the variants and distinguish their outputs if publishing artifacts. |
| `!reference` | GitLab YAML tag selecting a definition path, such as `before_script: !reference [.windows_rust, before_script]`. | In an alternative design, copies just the toolchain probe across the included-file boundary. YAML anchors cannot do that across files. Avoid interpolated inputs in reference paths. | Confirm the referenced path exists in expanded YAML and validate with a GitLab-aware parser. |
| Legacy `only/except` | Deprecated job filters, such as `only: [branches]`. | An older branch job may behave differently from an MR job using rules. Mixing styles can create inconsistent graphs. | Inventory existing behavior before translating it into explicit event rules. |

See the [GitLab YAML reference](https://docs.gitlab.com/ci/yaml/), [reuse documentation](https://docs.gitlab.com/ci/yaml/yaml_optimization/) and [CI Lint](https://docs.gitlab.com/ci/yaml/lint/).

## Review questions and worked answers

1. **An MR pipeline fails to create when it changes only documentation. What if `optional: true` was removed?**  
   **Answer** — `package_tests` is excluded by job rules, leaving an invalid required edge. Restore optionality only if summary legitimately works without package tests. If tests are required, align their inclusion rules with the consumer.
2. **A matrix test fails. Does the optional edge let the summary ignore it?**  
   **Answer** — The edge is optional only when the job is absent. A present test failure still affects the normal success path. Verify failure policy separately from graph membership.
3. **Diagnostics still runs the Rust version probe after disabling defaults. Where did it come from?**  
   **Answer** — The probe comes from the extended hidden definition. To replace it in diagnostics, define a job-level `before_script` or use a narrower parent.
4. **The summary turns green while a web pipeline is blocked. Which edge is missing?**  
   **Answer** — No edge from summary to diagnostics is defined. Its blocking manual status affects the pipeline as a whole. Decide whether summary is only about validation or should explicitly wait for diagnostics when included.

## Acceptance

Produce the expanded settings for one extended job, explain all seven event outcomes, and distinguish a rejected pipeline, an omitted job, a missing required edge and a blocked manual action. Check the effect of moving the suppression rule below the branch-push rule. No runner is needed to reason about these cases. Runtime validation remains in [Future labs](../../FUTURE-LABS.md).
