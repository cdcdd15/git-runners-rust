# P3.1 · Read a complete GitLab CI file from zero

**Access** — Offline. Allow 60–75 minutes. Start with the [P0 execution diagrams](../architecture/README.md) and the [Cargo build review](p2-2-review-cargo-build-and-packaging.md). All configurations and diagnostics here are illustrative and unexecuted.

Ledger Gateway needs two checks on its existing Windows Rust runner. One validates that Cargo can resolve the committed workspace without changing its lockfile. The second runs the tests. Your task is to read the file as three systems would: a YAML parser builds a data structure, GitLab validates it and schedules jobs, and PowerShell interprets each command after a runner accepts a job. A valid YAML document can still fail either later layer.

## Start with one job

This is an entire minimal `.gitlab-ci.yml`. The job uses the implicit `test` stage because neither a stage list nor a job stage is supplied. The tag routes it to the Windows pool, where we assume a Shell executor using PowerShell Core.

```yaml
check:
  tags: [windows-rust]
  script:
    - cargo --version
```

Read each indentation level before reading the commands. `check:` names a top-level mapping entry, and its indented keys belong to that job. `[windows-rust]` is a compact sequence, equivalent to a block list with a single dash-prefixed item. `script` contains a sequence of strings. Use spaces for indentation and align sibling keys. A colon followed by a space can turn an unquoted command into a mapping, even when the shell arguments contain quotes. Quote the whole YAML scalar or put it in a block. With `|`, YAML preserves line breaks inside one string. With `>`, it generally folds ordinary line breaks into spaces. For separate PowerShell statements, use separate list items or a literal block. [GitLab script quoting and multiline commands](https://docs.gitlab.com/ci/yaml/script/)

## Complete Windows Shell example

Assume a checkout with a committed workspace lockfile, an eligible runner tagged `windows-rust`, and Cargo on the runner service account's PATH. The runner is configured with the Shell executor and `pwsh`. The repository requires no additional setup for these commands. This file deliberately leaves event-specific admission and job rules for [P3.2](../roadmap/P3.md#p32--review-a-reusable-pipeline-graph).

```yaml
stages: [validate, test]

default:
  tags: [windows-rust]
  before_script:
    - rustc --version

validate_lock:
  stage: validate
  timeout: 10 minutes
  script:
    - |
      Write-Host "Check: locked Cargo workspace"
      cargo metadata --locked --format-version 1 | Out-Null
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

test_workspace:
  stage: test
  timeout: 25 minutes
  retry:
    max: 1
    when: runner_system_failure
  script:
    - cargo test --workspace --locked
  after_script:
    - 'Write-Host "Finalization: $env:CI_JOB_STATUS"'
```

For a pipeline that GitLab creates from this file, both jobs are present. GitLab orders `validate_lock` before `test_workspace` through the stage barrier. The test job normally starts only after the earlier stage succeeds. Both jobs inherit `tags` and `before_script` independently, so each runs `rustc --version` before its main commands. The tag matches runner metadata. The host and shell are properties of the matched runner, and scope, protection and capacity also affect assignment.

The validation job checks the locked resolution and explicitly propagates Cargo's exit status after discarding its JSON output. The test job allows one automatic retry for a failure classified as `runner_system_failure`. A normal test assertion failure is a script failure. Check the deployed GitLab version and actual failure classification before assuming that an infrastructure failure will match this retry policy. Both timeout values are defined on the jobs and are subject to the runner's maximum. [GitLab YAML reference](https://docs.gitlab.com/ci/yaml/), [runner configuration](https://docs.gitlab.com/ci/runners/configure_runners/)

The finalization message uses a YAML-quoted scalar so the colon is preserved. PowerShell still receives its own double-quoted string and can expand the environment variable. Runner executes `after_script` in a separate shell when applicable. It has a separate timeout, and a failure there does not turn a successful main script into a failed job. Shell variables or a directory change from `script` are unavailable in that shell. Keep mandatory validation in the main script. [GitLab job execution flow](https://docs.gitlab.com/ci/jobs/job_execution/), [after_script](https://docs.gitlab.com/ci/yaml/#after_script)

## Separate Linux container example

This is a complete alternative file for a project with a **Linux Docker executor** tagged `linux-docker`. Assume image pulls are allowed. The example uses public image tags for readability. In an enterprise repository, use approved image versions or digests, an approved registry, and the runner's required pull policy.

```yaml
container_smoke:
  tags: [linux-docker]
  image: rust:1.85-bookworm
  services:
    - name: redis:7.4-alpine
      alias: redis
  script:
    - cargo --version
    - getent hosts redis
```

Runner starts the job in the Rust image and the service in a separate Redis container reachable through its alias. The smoke check exercises command availability and service DNS. An application integration test should also establish service readiness and exercise the protocol. A Windows Shell runner executes installed host tools and does not create these containers from the YAML keywords. Adding both Windows and Linux tags to a single job would require a runner matching **both** tags. [GitLab Docker executor](https://docs.gitlab.com/runner/executors/docker/), [GitLab services](https://docs.gitlab.com/ci/services/)

## Core keyword review card

Minimal forms below are inline YAML shapes unless explicitly shown as a command value. Job-level entries belong inside a job mapping. When reviewing a real repository, compare the merged configuration with the examples, then use CI Lint on the target instance when authorized.

| Keyword | Purpose, scope and minimal form | Enterprise use above | Typical error and review check |
|---|---|---|---|
| Job name | Top-level key for a job mapping, such as `check: {script: [cargo --version]}`. | `validate_lock` and `test_workspace` give the two checks traceable names. | An incorrectly indented job becomes part of another mapping. Check top-level keys and avoid reserved global keyword names or duplicate names. |
| `stages` | Global ordered list, such as `stages: [test]`. | `[validate, test]` defines a validation barrier. | The list is mistaken for job names. Compare each job's stage value with the configured list. |
| `stage` | Job-level string, such as `stage: test`. | `stage: validate` places the lock check first. | A typo gives a job an unknown stage. Verify the exact spelling and the default `test` when omitted. |
| `script` | Job command string or sequence, such as `script: [cargo --version]`. | The literal block checks locked resolution and handles the native exit code. | A command containing colon-space parses as a mapping. Inspect the parsed value's type and then read the command for the assigned shell. |
| `before_script` | Job or default command sequence, such as `before_script: [rustc --version]`. | A shared toolchain probe precedes both main scripts. | A job-level list replaces the default list for that job. Check the effective list and tool availability. |
| `after_script` | Job or default command sequence, such as `after_script: [Get-Location]`. | Emits finalization context on the test job. | Cleanup expects a shell-local variable from the main script. Review which state must survive on disk and keep required checks in `script`. |
| `default` | Global mapping of supported default keywords, such as `default: {tags: [windows-rust]}`. | Shares routing and the toolchain probe across Windows jobs. | A job-level value is assumed to append to the default for that keyword. Compare inherited and explicitly replaced keys. |
| `tags` | Job or default sequence, such as `tags: [windows-rust]`. | Selects the Windows pool or the Linux Docker pool in the respective examples. | An eligible runner must have every job tag. Compare the full list with runner scope, protection and availability. |
| `timeout` | Job-level duration, such as `timeout: 10 minutes`. | Bounds lock validation and workspace testing separately. | A timeout is put under `default` or exceeds the runner maximum. Check keyword placement and the runner limit. |
| `retry` | Job or default retry count or mapping, such as `retry: 1`. | Retries the test job once for the specified runner failure reason. | A bare retry count retries broad failure categories. Inspect the configured reason and whether rerunning the whole job is safe. |
| `image` | Job or default container image, such as `image: rust:1.85-bookworm`. | Supplies the Linux job's toolchain. | A Shell job expects the image to provide Cargo. Confirm the executor supports the keyword and can pull the approved image. |
| `services` | Job or default list of companion images, such as `services: [redis:7.4-alpine]`. | Gives the Docker job a Redis companion with a known alias. | A script assumes the service executable is installed inside the job image or that DNS proves readiness. Check executor support, aliases and the protocol used by the test. |

For Maven readers, `validate` and `test` may look like Maven lifecycle phases. Here they are GitLab ordering labels. Jobs may run on different machines and each starts its own commands. Any file transfer between them requires an explicit handoff.

## Offline review and worked answers

1. **YAML type** — Why is `- Write-Host "Check: lockfile"` unsafe as an unquoted list item under `script`?  
   **Answer** — The entire YAML item begins unquoted. The colon followed by a space may make it a mapping, while GitLab expects a script string. Use a literal block or write `- 'Write-Host "Check: lockfile"'`.
2. **GitLab schema** — Someone indents a job correctly and sets `stage: verify` in the Windows example. Why can a YAML parser accept it?  
   **Answer** — YAML accepts the string. GitLab checks whether that stage exists in the declared stage list. Use `validate` or `test`, or explicitly add and review the new stage and its ordering.
3. **Inheritance and assignment** — A reviewer adds `tags: [large-memory]` to the test job. Does it still require `windows-rust`?  
   **Answer** — The job-level sequence replaces the default. Add both tags explicitly if both capabilities are required, and check that a runner has both.
4. **Execution** — GitLab accepts a job that uses `image: rust:1.85-bookworm` but its selected Windows Shell runner reports Cargo missing. What failed?  
   **Answer** — Host tool lookup failed after assignment. The Shell executor does not use `image` to provide the toolchain. Check the executable available to the runner's service account.
5. **Retry and finalization** — A normal test assertion fails. Will a successful finalization message turn the job green or trigger a retry?  
   **Answer** — The message does neither. The test failure controls the outcome, and the failure category does not match the configured retry reason.

## Acceptance

Explain the expected two-job order and the effective settings for each job. Classify each worked error as YAML shape, GitLab configuration, assignment or shell execution, and propose a scoped correction. A local YAML parser can check structure. GitLab CI Lint adds GitLab-specific validation and can simulate pipeline creation, but a simulation of a particular event and ref cannot establish every graph or exercise the runner. Runtime practice remains in [Future labs](../../FUTURE-LABS.md). [CI Lint](https://docs.gitlab.com/ci/yaml/lint/)
