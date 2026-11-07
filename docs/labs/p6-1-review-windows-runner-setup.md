# P6.1 · Review Windows runner setup and configuration

**Access** — Offline. Allow 50–65 minutes. Read [job execution](../architecture/README.md), [runner tags in YAML](p3-1-read-a-complete-gitlab-ci-file.md) and [protected variables and runners](p4-2-review-secret-and-scope-boundaries.md). The registration procedure, commands, settings and evidence below are illustrative and unexecuted. The host, account and endpoint are fictional.

Ledger Gateway wants to route protected release builds to a Windows MSVC pool. Review the proposed GitLab runner record and host service separately. GitLab owns the runner's eligibility. The Windows service loads a local configuration, authenticates to GitLab and requests work. After assignment, the Shell executor runs the generated script on the host under the service identity. The shell decides how the script syntax is interpreted.

## Review the setup sequence

| Step | Owner and expected evidence |
|---|---|
| 1. Prepare a dedicated Windows VM | Windows operations selects the approved GitLab Runner build for the host architecture and verifies it against the approved distribution. In this fixture, the executable and configuration live under `C:\GitLab-Runner`. Administrators control writes to that directory. |
| 2. Establish the service identity | Windows operations provisions a dedicated low-privilege identity and grants **Log on as a service**. It can read the runner executable and configuration and write to the designated build and cache directories. Restrict other users' access to the token-bearing configuration. |
| 3. Prepare the job toolchain | The build-image or host owner makes Git, PowerShell 7, the pinned Rust toolchain, MSVC build tools and Windows SDK available to the service identity. Review which scanner tools and endpoints are needed by authorized jobs. An administrator's interactive PATH and rustup state are separate evidence. |
| 4. Create the runner record | A project Maintainer opens **Settings → CI/CD → Runners** in the project and creates a project runner. In this example it has `windows-rust`, `msvc` and `release` tags, is protected, and is configured to reject untagged jobs. |
| 5. Register the runner manager | The host operator supplies the instance URL and the new runner authentication token in the approved registration workflow, selecting the `shell` executor. Registration writes the local `config.toml`. Server-side scope, tags and protection come from the runner record in this workflow. |
| 6. Review the service binding | Windows operations installs the service with the approved identity and the explicit config path, then starts it in the separately authorized runtime lab. Record the service account, active config path and executable path. Registration alone does not install or start a Windows service. |

With the documented authentication-token workflow, the token has a `glrt-` prefix and is distinct from the deprecated registration token. Keep real tokens out of Git, job logs and shared transcripts. Verify actual UI labels and permissions for the deployed versions. Current GitLab documentation identifies project Maintainer for creating a project runner, group Owner for creating a group runner, and instance administrator for creating an instance runner on self-managed GitLab. Project runners are assigned to projects, group runners can serve descendants and instance runners can serve projects across the instance subject to settings. [Runner scopes](https://docs.gitlab.com/ci/runners/runners_scope/), [registration](https://docs.gitlab.com/runner/register/)

### Read the command sequence

This is a paper walkthrough. Registration is interactive so the example does not place a token in a command. The service installation line shows placeholder arguments for an account that uses a password. In an enterprise environment, Windows operations supplies the identity and credentials through its approved service-provisioning process. Command-line credentials may be exposed to process inspection or logging.

```powershell
Set-Location -LiteralPath 'C:\GitLab-Runner'
.\gitlab-runner.exe register --config 'C:\GitLab-Runner\config.toml'
# Registration prompts: instance URL, runner authentication token, executor (shell).
# After reviewing the resulting configuration, install as the designated identity.
.\gitlab-runner.exe install --config 'C:\GitLab-Runner\config.toml' --working-directory 'C:\GitLab-Runner' --user 'CORP\svc-ledger-runner' --password '<service-account-password>'
.\gitlab-runner.exe start
```

The working directory and explicit configuration path eliminate ambiguity about what the service loads. The service installation and start require appropriate Windows administrative access. GitLab privileges to create a runner do not grant Windows service permissions. [Windows installation](https://docs.gitlab.com/runner/install/windows/), [Runner command reference](https://docs.gitlab.com/runner/commands/)

## Read the local configuration

This is a sanitized representation of the registered configuration after review. Single-quoted TOML literal strings preserve Windows backslashes. The placeholder token cannot register or authenticate a runner.

```toml
concurrent = 1

[[runners]]
name = "ledger-release-windows"
url = "https://gitlab.example.invalid"
token = "<runner-authentication-token>"
executor = "shell"
shell = "pwsh"
builds_dir = 'D:\GitLab-Runner\builds'
cache_dir = 'D:\GitLab-Runner\cache'
limit = 1
request_concurrency = 1
```

| Setting | What to infer |
|---|---|
| `executor = "shell"` | Jobs run on the Windows host with installed tools. The job's `image` or `services` keywords do not provision containers on this executor. |
| `shell = "pwsh"` | The generated script runs in PowerShell Core. The alternative `powershell` selects Windows PowerShell. Match syntax and tooling to the configured shell instead of relying on defaults. |
| `builds_dir`, `cache_dir` | These override the local base paths. The service identity needs appropriate access. Jobs should reference `$env:CI_PROJECT_DIR` rather than assume the full checkout path. A local cache directory does not imply shared cache storage. |
| `concurrent`, `limit` | The first caps jobs across the runner manager's configuration. The second caps jobs for this runner entry. The fixture starts with one job slot. |
| `request_concurrency` | Caps concurrent requests for new jobs, independently of how many jobs can execute. Increasing it alone does not increase execution slots. |

Shell jobs share the host and service identity. Serial execution reduces contention, while files and changes can persist across jobs. Use a dedicated VM or separately isolated pool for trusted release work. The current GitLab documentation places the Shell executor in maintenance mode. Treat this lab as a review of an existing Shell deployment. [Advanced configuration](https://docs.gitlab.com/runner/configuration/advanced-configuration/), [Shell executor](https://docs.gitlab.com/runner/executors/shell/), [supported shells](https://docs.gitlab.com/runner/shells/)

## Review routing and verification evidence

This illustrative job selects protected default-branch pushes. Matching tags are necessary for assignment. GitLab must also make the runner available to this project, allow the ref, and have capacity. The server-side **Protected** setting is distinct from the runner having a tag called `release`.

```yaml
release_probe:
  tags: [windows-rust, msvc, release]
  rules:
    - if: '$CI_PIPELINE_SOURCE == "push" && $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH && $CI_COMMIT_REF_PROTECTED == "true"'
  script:
    - whoami
    - Get-Command git, pwsh, cargo, rustc -ErrorAction Stop
    - rustc -vV
```

A future runtime review would use separate evidence for each boundary. These example commands are shown for interpretation:

```powershell
Get-Service -Name 'gitlab-runner'
Get-CimInstance Win32_Service -Filter "Name='gitlab-runner'" |
    Select-Object Name, State, StartName, PathName
.\gitlab-runner.exe verify --config 'C:\GitLab-Runner\config.toml'
```

The service query establishes status and configuration. `verify` checks registered runner connectivity to GitLab, using the environment of the invoking process. It does not establish that the Windows service is running, loaded the same config or can execute a given job. A job trace establishes the actual assignment and service-context tool lookup. `rustc -vV` identifies the Rust toolchain and host triple. A successful native build provides additional linker and SDK evidence. Compare with the next step's [service-context review](../roadmap/P6.md#p62--diagnose-a-windows-service-context-failure). [GitLab Runner verify](https://docs.gitlab.com/runner/commands/#gitlab-runner-verify), [runner configuration](https://docs.gitlab.com/ci/runners/configure_runners/)

## Offline review and worked answers

1. **A protected default-branch job stays pending. The online runner has `windows-rust` and `release` tags. What is missing?**  
   **Answer** — The job also requires `msvc`. Confirm the host actually has the required toolchain before adding the tag or route to a qualified runner. Check project assignment and capacity separately.
2. **An administrator sees a successful `verify`, but Windows reports the service stopped. Which evidence wins?**  
   **Answer** — Each describes a different boundary. The CLI could authenticate using that local config, but the service is stopped. Review service startup, account logon rights and the service's configured executable and config path.
3. **A job finds Cargo in an administrator console, but its trace shows a different identity. Can you approve the runner?**  
   **Answer** — The administrator check cannot establish the service environment. Review executable resolution, PATH, toolchain and MSVC availability under the job identity. The eventual acceptance trace should include a native compile.
4. **The team wants to run untrusted merge requests on the same VM but promises to keep concurrency at one. What is the isolation issue?**  
   **Answer** — Jobs still share the service account and persistent host. Serial jobs can read or affect state left by previous jobs. Use a separate trust boundary, such as an isolated runner pool, for untrusted work.

## Acceptance

Identify the owner and evidence for each setup step. Explain which jobs match the tags and protected ref, which account runs them, where local builds and caches live, and what a successful `verify` establishes. Record why the dedicated Windows VM is part of the release trust boundary. Live registration and execution remain in [Future labs](../../FUTURE-LABS.md).
