# How GitLab connects to a Windows Runner — no-admin setup

## The central idea

**GitLab does not connect to your Windows computer. Your Windows computer connects to GitLab.** The `gitlab-runner.exe` process initiates outbound HTTPS requests to the GitLab instance, authenticates with a runner authentication token, and asks whether an eligible CI job is available. GitLab responds with work, and the runner executes it locally.

This is why **Settings → CI/CD → Runners** has no field for a Windows machine's IP address, path, hostname or inbound URL. GitLab is not remotely opening PowerShell on your PC.

```mermaid
sequenceDiagram
    participant UI as GitLab UI / Coordinator
    participant WR as gitlab-runner.exe on Windows
    participant PS as Local PowerShell
    UI->>UI: Runner record created; authentication token issued
    Note over WR: Local config.toml contains GitLab URL and token
    WR->>UI: Outbound HTTPS: request eligible job (authenticated)
    UI-->>WR: Job details or no work available
    WR->>PS: Run generated CI script locally
    PS-->>WR: Output and exit code
    WR->>UI: Outbound HTTPS: send trace and job result
    UI-->>WR: Acknowledge
```

## What exists on each side?

| Location | Information | Responsibility |
|---|---|---|
| GitLab UI | Runner record, tags, scope, protected status, availability | Decide which jobs this runner may accept |
| Windows user folder | `gitlab-runner.exe` | Agent that requests and executes jobs |
| Windows user folder | `config.toml` with `url`, `token`, `executor`, `shell` | Tell the agent which GitLab server to contact and how to run jobs |
| GitLab repository | `.gitlab-ci.yml` | Define the pipeline, job tags and PowerShell/Cargo commands |
| Windows PowerShell | Running `gitlab-runner.exe run ...` process | Keep the runner available without installing a service |

## Minimal linking procedure

### Step 1 — Create the runner record in GitLab

In the GitLab project, open **Settings → CI/CD → Runners** and create a **project runner**. Give it the tag `windows-cargo` (or another tag you will use consistently). Copy the runner authentication token; modern tokens commonly start with `glrt-`. Treat the token as a secret.

**Expected:** A runner record exists in GitLab. It may appear **offline** until a Windows runner process connects.

### Step 2 — Register from Windows (outbound connection)

In a normal, non-administrator PowerShell window, from your user-owned folder:

```powershell
cd "$HOME\gitlab-runner-lab"
.\gitlab-runner.exe register --config .\config.toml
```

Enter the GitLab URL, the authentication token copied from GitLab, and `shell` as executor. Choose `powershell` for Windows PowerShell when prompted/configured. The registration workflow writes local configuration. It does **not** tell GitLab to contact the Windows machine.

**Expected:** A `config.toml` file is created or updated. A simplified example (never commit the real token):

```toml
[[runners]]
  name = "windows-cargo-local"
  url = "https://gitlab.example.com/"
  token = "<SECRET_RUNNER_AUTHENTICATION_TOKEN>"
  executor = "shell"
  shell = "powershell"
```

The URL is **GitLab's address**, not your Windows PC's address. The token associates this local agent with the runner record created in GitLab. The exact generated fields can vary by GitLab Runner version.

### Step 3 — Start the runner as a normal user process

```powershell
cd "$HOME\gitlab-runner-lab"
.\gitlab-runner.exe run --config .\config.toml --working-directory .
```

Leave this PowerShell window open. The runner now requests jobs from GitLab over outbound HTTPS. No Windows service installation, administrator rights or persistent PATH changes are required.

**Expected:** GitLab shows the runner online after it connects. If it stays offline, inspect the runner console for authentication, URL, TLS, DNS or proxy errors.

### Step 4 — Match the pipeline job to the runner

The project `.gitlab-ci.yml` can contain:

```yaml
stages: [test]

cargo_check_windows:
  stage: test
  tags: [windows-cargo]
  script:
    - 'cargo --version'
    - 'cargo check --locked'
    - 'if ($LASTEXITCODE -ne 0) { throw "Cargo check failed" }'
```

The repository must also contain a valid `Cargo.toml`, `Cargo.lock` and Rust source file as described in the Cargo setup guide. GitLab uses the **tag and runner eligibility rules** to offer this job to the runner; the tag is **not** a network address or remote host selector.

**Expected:** After you push the files, the pipeline job starts on the Windows machine and GitLab receives its output.

## How does GitLab know which physical machine it is?

It primarily knows the authenticated runner identity, not a Windows path or an inbound endpoint. Runner metadata and job logs can expose information such as the runner manager/system identifier, executor and host environment, but **the token and runner record are what authorize job requests**. The server does not need a route to the Windows machine for normal job execution.

The machine may be behind NAT or a corporate firewall, provided it can reach the GitLab server and required endpoints. No public IP address, inbound port forwarding or SSH server is needed for this workflow. Corporate proxy and TLS trust policies can still affect outbound requests.

## What happens if the Windows process stops?

GitLab retains the runner record and queued jobs. The runner stops requesting work and will eventually be shown as offline. New eligible jobs may remain pending unless another matching runner is available. Restart the command in Step 3 to reconnect; registration usually does not need to be repeated.

## Common misconceptions

| Assumption | Correct explanation |
|---|---|
| “GitLab needs my Windows IP” | No; Windows initiates the connection |
| “The runner tag is the machine hostname” | No; it is a scheduling label |
| “Registering installs a service” | No; registration and service installation are separate |
| “Runner online means Cargo is installed” | No; it only indicates connectivity/availability |
| “I must change system PATH” | No; invoke runner by explicit path; Cargo can use a session-only PATH if needed |
| “The GitLab server executes the PowerShell script” | No; the Windows runner executes it locally |

## No-admin and no-persistent-environment-variable constraints

- Store `gitlab-runner.exe` and `config.toml` in a directory owned by your Windows account.
- Run the agent from an ordinary PowerShell session, not as a service.
- Use `./gitlab-runner.exe` (or `.\gitlab-runner.exe` in PowerShell) so the runner executable does not need to be on PATH.
- If Cargo exists under your user profile but is not on PATH, set a **temporary** process-scoped PATH before starting the runner:

```powershell
$env:PATH = "$HOME\.cargo\bin;$env:PATH"
.\gitlab-runner.exe run --config .\config.toml --working-directory .
```

This affects the current PowerShell process and child processes only; it does not modify Windows user or system environment variable settings. It assumes Rust/Cargo is already installed in your user profile. Installing Rust without admin privileges depends on the chosen installer and enterprise policy.

## Verification checklist

- [ ] GitLab runner record exists with tag `windows-cargo`.
- [ ] Windows `config.toml` contains the **GitLab URL**, authentication token and Shell executor.
- [ ] `gitlab-runner.exe run` is running in a normal PowerShell window.
- [ ] GitLab shows the runner online.
- [ ] The `.gitlab-ci.yml` job uses the matching tag.
- [ ] The job starts and prints output in the GitLab job trace.

**One-sentence summary:** The runner is a **client of GitLab**, not a server that GitLab must reach.

## Official references

- [GitLab Runner architecture](https://docs.gitlab.com/runner/)
- [Registering runners](https://docs.gitlab.com/runner/register/)
- [GitLab Runner commands](https://docs.gitlab.com/runner/commands/)
- [CI/CD job tags](https://docs.gitlab.com/ci/runners/configure_runners/)
