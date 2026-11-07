# P4.2 · Review secret and scope boundaries

**Access** — Offline. Allow 45–60 minutes. Start with [P4.1 precedence](p4-1-review-variable-permissions-and-precedence.md). The project settings, YAML and outcomes below are illustrative and unexecuted. The fixture uses dummy values and performs no deployment or scanner call.

Ledger Gateway needs ordinary tests on merge requests and a release-only check of scanner credential wiring. A previous job received a project variable simply because its scope was `*`. Review which jobs should receive each variable, how the variable appears in PowerShell, and which settings owner should handle a mismatch.

## Settings fixture

Assume `main` and `release/1.0` are protected, `feature/routing` is unprotected, and no pipeline, policy or same-name inherited overrides apply. The lab keeps access to protected resources disabled in merge request pipelines. The project is assumed to support the visibility choices below.

The project Maintainer reviews these records under **Project → Settings → CI/CD → Variables**. If a record instead comes from **Group → Settings → CI/CD → Variables**, ask the owning group's Owner to review it. Access to change protected branches, protected environments, runner settings and vendor credentials is governed separately. [P4.1 permissions](p4-1-review-variable-permissions-and-precedence.md), [GitLab protected environments](https://docs.gitlab.com/ci/environments/protected_environments/)

| Dummy key | Type | Protected | Environment scope | Visibility and purpose |
|---|---|---|---|---|
| `LEDGER_LAB_BUILD_LABEL` | Variable | No | `*` | Visible. Nonsecret input available even to jobs with no environment. |
| `LEDGER_LAB_PREVIEW_LABEL` | Variable | No | `preview/*` | Visible. Nonsecret input for preview diagnostics. |
| `LEDGER_LAB_RELEASE_TOKEN` | Variable | Yes | `release-scan` | Masked and hidden. Dummy token representing a scanner credential. |
| `LEDGER_LAB_RELEASE_CA` | File | Yes | `release-scan` | Visible in this fixture. Dummy text representing a CA bundle path contract. |

Variable type determines the runtime interface. An ordinary variable exposes its value through `$env:KEY`. For a file-type variable, Runner materializes the value as a temporary file and places **the file path** in `$env:KEY`. Give a file-aware tool that path. File type is a delivery mechanism, and any process with access to the job's file can read its contents. A YAML `variables:` entry alone creates an ordinary variable. [GitLab file-type variables](https://docs.gitlab.com/ci/variables/#use-file-type-cicd-variables)

Protection and environment scope both have to match. Masking aims to redact supported log output. Hiding prevents retrieval of the saved value in the settings UI after creation. Neither visibility setting prevents a job that receives a value from reading it or sending it elsewhere. Hiding must be chosen when adding a variable on versions that support it. Avoid using environment-scoped values in `rules` or `include` because they might be unavailable during configuration validation. [GitLab variable security](https://docs.gitlab.com/ci/variables/#cicd-variable-security), [environment scopes](https://docs.gitlab.com/ci/environments/#limit-the-environment-scope-of-a-cicd-variable)

## Complete illustrative .gitlab-ci.yml

Assume Windows Shell runners with PowerShell Core. The `windows-rust` pool runs ordinary checks. The separate `windows-protected` pool is configured as protected in GitLab and reserved for trusted jobs. The tag itself does not provide protection. The environments here use `action: verify` for a check without creating a deployment. Each probe reports booleans and never prints the value or path.

```yaml
workflow:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_PIPELINE_SOURCE == "push" && $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS'
      when: never
    - if: '$CI_PIPELINE_SOURCE == "push" && $CI_COMMIT_BRANCH'

stages: [verify]

.scope_probe:
  stage: verify
  script:
    - |
      $buildLabelPresent = -not [string]::IsNullOrEmpty($env:LEDGER_LAB_BUILD_LABEL)
      $previewLabelPresent = -not [string]::IsNullOrEmpty($env:LEDGER_LAB_PREVIEW_LABEL)
      $releaseTokenPresent = -not [string]::IsNullOrEmpty($env:LEDGER_LAB_RELEASE_TOKEN)
      $caPath = $env:LEDGER_LAB_RELEASE_CA
      $caPresent = -not [string]::IsNullOrEmpty($caPath)
      $caIsFile = $caPresent -and (Test-Path -LiteralPath $caPath -PathType Leaf)
      Write-Host "Build label present: $buildLabelPresent"
      Write-Host "Preview label present: $previewLabelPresent"
      Write-Host "Release token present: $releaseTokenPresent"
      Write-Host "Release CA path present: $caPresent"
      Write-Host "Release CA path is a file: $caIsFile"

workspace_probe:
  extends: .scope_probe
  tags: [windows-rust]
  rules:
    - when: on_success

preview_probe:
  extends: .scope_probe
  tags: [windows-rust]
  rules:
    - if: '$CI_PIPELINE_SOURCE == "push" && $CI_COMMIT_BRANCH != $CI_DEFAULT_BRANCH'
  environment:
    name: preview/$CI_COMMIT_REF_SLUG
    action: verify

release_probe:
  extends: .scope_probe
  tags: [windows-protected]
  rules:
    - if: '$CI_PIPELINE_SOURCE == "push" && $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH && $CI_COMMIT_REF_PROTECTED == "true"'
  environment:
    name: release-scan
    action: verify
```

Read each job in this order: evaluate its event rule, determine its environment name, check ref protection and scope, then apply [precedence](p4-1-review-variable-permissions-and-precedence.md) among eligible definitions. Runner assignment is a separate question. The ordinary probe is explicitly included in MR pipelines. The release probe selects a protected default-branch push and binds the exact environment name. An ordinary test job in the same pipeline does not inherit that environment. [GitLab environment action](https://docs.gitlab.com/ci/yaml/#environmentaction), [protected runners](https://docs.gitlab.com/ci/runners/configure_runners/#prevent-runners-from-revealing-sensitive-information)

## Worked access matrix

| Scenario and job | Build label | Preview label | Release token | Release CA |
|---|---|---|---|---|
| Ordinary MR, `workspace_probe` | Value | Absent | Absent | Absent |
| Push to `feature/routing` with no open MR, `preview_probe` | Value | Value | Absent | Absent |
| Push to protected `release/1.0` with no open MR, `preview_probe` | Value | Value | Absent | Absent |
| Push to protected `main`, `workspace_probe` | Value | Absent | Absent | Absent |
| Push to protected `main`, `release_probe` | Value | Absent | Value | Temporary file path |
| Hypothetical unprotected branch push that is allowed by edited rules to run a job in `release-scan` | Value | Absent | Absent | Absent |

A protected branch with the wrong environment fails the scope check. An unprotected branch with the right environment fails the protection check. The last row isolates the protection decision. The unchanged fixture never creates a release job for that event. If `main` loses branch protection, the release job is omitted by its rule.

## Review and troubleshooting questions

1. **The release probe never appears in an MR targeting protected `main`. Which setting should you investigate first?**  
   **Answer** — Check the job rule and the pipeline source first. This fixture admits the release job only for a protected default-branch push. On supported GitLab versions, MR access to protected resources requires the project feature to be enabled, protected source and target branches in the same project, and a triggering user with push or merge access to the target. A fork MR does not meet those protected-resource conditions. A parent-project pipeline started for a fork MR can still expose other parent-project resources to fork-controlled code, so review that execution path separately. [Merge request pipelines and protected resources](https://docs.gitlab.com/ci/pipelines/merge_request_pipelines/#control-access-to-protected-variables-and-runners)
2. **The release job exists but both release inputs are absent. What evidence would separate scope from protection?**  
   **Answer** — Compare the actual pipeline source and ref protection with the job's resolved environment name and the stored variable scopes. A job using `release_scan` does not match `release-scan`. Check for higher-priority same-name values after checking eligibility. Ask the project Maintainer or owning group Owner to inspect metadata without disclosing values.
3. **The CA path is present but does not resolve to a file. What do you check?**  
   **Answer** — Verify that the winning setting is file type, then check whether the runner created an accessible file under the job identity. An ordinary variable supplied as a same-name override might contain certificate text instead of a path. Report only presence and path type. A file at that path does not prove valid PEM, correct trust or connectivity.
4. **A reviewer proposes setting the scope to `*` to make missing credentials easier to debug. What changes?**  
   **Answer** — Other jobs on eligible refs could receive the credentials. Keep the scope and fix the environment name or credential wiring. Separate SonarQube, Nexus IQ and Fortify identities and authorize each for the operations it needs. Avoid exposing one tool's credential to jobs that only call another tool, and keep credentials out of logs, artifacts, caches and dotenv reports. Confirm each tool's supported input interface with its vendor documentation.

## Acceptance

Predict all six access rows and explain which job, protection and scope checks control each outcome. Explain why visibility and file type cannot replace eligibility, name the settings owner for an inherited variable, and propose a safe check for a missing file without displaying its path or content. Runtime verification is tracked in [Future labs](../../FUTURE-LABS.md).
