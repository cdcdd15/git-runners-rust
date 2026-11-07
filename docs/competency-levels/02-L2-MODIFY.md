# L2 · Modify

L2 starts with the ability to explain an existing pipeline from event to result. Given an approved business objective, prepare a reviewable configuration diff. Explain where each decision belongs, who owns it, which paths change and what could break. The Ledger Gateway examples are independent excerpts and are illustrative and unexecuted. Assume included templates are pinned and inspect their expanded jobs before adapting any example. [L1 baseline](01-L1-UNDERSTAND.md)

## Work from request to impact

Write the requested outcome in observable terms. Capture the current event, ref, graph, platform, toolchain, data transfers and credentials. Mark the smallest affected boundary. Put job behavior in versioned YAML, toolchain requirements in build configuration, runner eligibility and service identity with their respective administrators, and policy thresholds with the policy owner. Compare the expected and unaffected paths before presenting the diff. Describe rollback as restoration of both configuration and policy behavior. A reverted YAML commit cannot reverse a settings change that was applied separately.

For GitLab review, identify permission to contribute a branch, approve and merge under project policy, and change any administrative setting separately. GitLab documents a Maintainer requirement for project variables and an Owner requirement for group variables. Protected branches, approval rules, custom roles and the deployed release may alter the effective workflow. Record the owner of each change and use the smallest permission scope. [Variables](https://docs.gitlab.com/ci/variables/), [roles](https://docs.gitlab.com/user/permissions/)

## Exercise 1 · Preserve behavior when moving tests to Windows

**Request** — Move the test job to an existing Windows Shell runner. Preserve ordinary MR checks and default-branch push checks. The team also wants this job excluded from maintenance schedules, which the enclosing workflow still admits for other jobs.

```yaml
# Before
test_rust:
  stage: test
  tags: [linux-rust]
  script:
    - cargo test --workspace --locked
```

```yaml
# After
test_rust:
  stage: test
  tags: [windows-rust]
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_PIPELINE_SOURCE == "push" && $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
  script:
    - |
      Set-Location -LiteralPath $env:CI_PROJECT_DIR
      cargo test --workspace --locked
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

The tag routes to the intended pool. The stage and Cargo test scope are preserved. PowerShell uses the process environment and a literal path. The explicit native exit check documents the desired failure behavior. The rules limit this job to the two events. Scheduled and manual pipelines previously admitted by the enclosing workflow lose this job. The schedule exclusion is intentional. Confirm that no manual release path or downstream job still requires the test before approving the new rules. For a host-only move, retain the existing event behavior.

**Permissions** — Branch contribution and normal merge approval suffice for the YAML change. Changes to runner assignment, tags or protection require the relevant runner administrator. Host tools and service identity belong to Windows operations.

**Static checklist** — Verify both rules against the enclosing workflow and review schedules and manual runs separately. Confirm that `test` exists, tags match an eligible runner, and PowerShell Core, Cargo and the Windows linker are part of the agreed host contract. Check that no Bash idioms or Linux-only dependencies remain.

## Exercise 2 · Separate speed from release provenance

**Request** — Keep dependency reuse on Windows while ensuring packaging reads the marker produced by this pipeline. Assume a committed lockfile, an agreed Windows MSVC toolchain and a producer in an earlier stage. The excerpt omits the designated cache writer.

```yaml
# Before
package_windows:
  stage: package
  cache:
    key: shared
    paths: [target/]
  script:
    - cargo build --release --locked
```

```yaml
# After
package_windows:
  stage: package
  variables:
    CARGO_HOME: '$CI_PROJECT_DIR/.cargo-ci'
  cache:
    key:
      prefix: windows-msvc-rust183-cache-v1
      files: [Cargo.lock]
    paths: [.cargo-ci/registry/]
    policy: pull
  needs:
    - job: prepare
      artifacts: true
  script:
    - |
      if ((Get-Content -LiteralPath build-commit.txt) -ne $env:CI_COMMIT_SHA) {
        throw "Unexpected build revision"
      }
      cargo build --release --locked
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

The cache now holds registry inputs under a project-relative directory, with a prefix for platform and toolchain policy and a key derived from the lockfile. A designated producer must populate the same key and path if warm restores are expected. The consumer only pulls, reducing competing writes. The marker travels separately through `needs` and is checked before building. `prepare` must publish the marker and exist in every graph that contains the consumer. The new dependency may let packaging start earlier than stage ordering previously allowed. Preserve required gate dependencies explicitly.

**Permissions and static checklist** — Use the normal CI configuration review. Coordinate any shared backend change with its operator. Trace a cold build, confirm matching producer paths and policies, and check lockfile changes, marker retention and every gate edge. Review cache paths for private dependency data and keep registry credential files outside the archive.

## Exercise 3 · Migrate a privileged quality job from Actions

**Request** — Preserve an approved push-only quality check for protected `main`. Assume the target runner has the approved quality scanner and repository script. Branch protection, job credential eligibility and the quality gate are part of the contract.

```yaml
# Before, GitHub Actions excerpt
on:
  push:
    branches: [main]
jobs:
  quality:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - shell: pwsh
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        run: ./ci/quality.ps1
```

```yaml
# After, GitLab excerpt
quality:
  stage: verify
  tags: [windows-protected]
  rules:
    - if: '$CI_PIPELINE_SOURCE == "push" && $CI_COMMIT_BRANCH == "main" && $CI_COMMIT_REF_PROTECTED == "true"'
  script:
    - ./ci/quality.ps1
```

GitLab Runner supplies the default source checkout. The existing script represents a repository-owned integration whose exit and gate behavior require review. The job rule replaces the Actions event filter at job scope. The credential should come from an approved protected project or group variable, with a compatible environment scope if configured. Confirm protection on the actual runner and branch. Apply the same event and credential review independently to Nexus IQ and Fortify. Preserve the IQ application and policy stage, and verify Fortify's supported scan mode and security verdict before preserving its release edge. [Vendor references](../concepts/README.md)

**Permissions and static checklist** — Obtain the appropriate settings owner for the secret and the normal merge approvals for YAML. Compare MR, fork, protected push and schedule outcomes. Check shell, checkout depth, vendor input paths and how the script surfaces gate failure versus service errors. Roll back the job definition and coordinate any settings rollback with the owner.

## Acceptance

Submit all three diffs with change owners, expected side effects, event predictions and a rollback path. Explain which behavior is assumed and what evidence a reviewer would need. Continue with [L3](03-L3-TROUBLESHOOT.md) and the [rubric](04-SUMMARY-VALIDATION.md).
