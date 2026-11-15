# Windows GitLab Runner — minimal Hello World pipeline

**Goal:** Run one GitLab CI job on a Windows machine that prints `Hello from Windows GitLab Runner!`.

**Scope:** Windows 10/11 or Windows Server, GitLab project access, GitLab Runner with the **Shell** executor, and PowerShell. No Rust, Docker, Maven or scanners.

## Prerequisites

- A Windows machine where you can install and start a Windows service (administrator rights).
- A GitLab project where you can create a project runner (normally Maintainer or Owner access, subject to instance policy).
- Network access from Windows to your GitLab server over HTTPS.
- Git installed on the Windows machine and available to the account that will run the runner. Git is needed for the default source checkout.
- PowerShell available (`powershell.exe` is built into supported Windows installations; PowerShell 7 `pwsh.exe` is optional).

> **Security:** The Shell executor runs repository-defined commands directly on the Windows host, under the runner service account. Use a dedicated test machine or VM, and restrict the runner to trusted projects. The example uses the default service setup for simplicity, not as a production security baseline.

## Step 1 — Download GitLab Runner on Windows

1. Create `C:\GitLab-Runner`.
2. Download the official Windows **amd64** GitLab Runner executable from the [GitLab Runner installation documentation](https://docs.gitlab.com/runner/install/windows/).
3. Save it as `C:\GitLab-Runner\gitlab-runner.exe`.
4. Open **PowerShell as Administrator** and check:

```powershell
cd C:\GitLab-Runner
.\gitlab-runner.exe --version
```

**Expected:** A GitLab Runner version is printed.

## Step 2 — Create a project runner in GitLab

1. Open your GitLab project.
2. Navigate to **Settings → CI/CD → Runners** (the exact UI labels can vary by GitLab version).
3. Select **New project runner** / **Create project runner**.
4. Configure:
   - **Tags:** `windows-hello`
   - **Run untagged jobs:** off (we will explicitly tag the job)
   - **Protected:** off for this initial test on an ordinary branch; use appropriate protection in production.
5. Create the runner and copy the **runner authentication token** shown by GitLab. Modern tokens typically begin with `glrt-`.

**Expected:** GitLab shows the runner's registration instructions and token. Keep the token secret; do not commit it or paste it into CI logs.

> If your organization disables project runner creation, ask the GitLab administrator to create or assign an appropriate runner. Do not use obsolete shared registration-token instructions from older tutorials.

## Step 3 — Register the Windows runner

In the same administrator PowerShell session:

```powershell
cd C:\GitLab-Runner
.\gitlab-runner.exe register
```

When prompted, enter:

| Prompt | Enter |
|---|---|
| GitLab instance URL | Your GitLab base URL, e.g. `https://gitlab.example.com/` |
| Runner authentication token | The token created in Step 2 (`glrt-...`) |
| Runner description/name | `windows-hello-local` (if requested) |
| Executor | `shell` |

Registration prompts vary by GitLab Runner version. With the modern authentication-token workflow, runner tags are managed when creating/editing the runner in GitLab, not by passing legacy registration options.

**Expected:** A successful registration message. A `config.toml` file is created in the runner's working/configuration directory.

## Step 4 — Ensure PowerShell is the shell

Open `C:\GitLab-Runner\config.toml` and locate the `[[runners]]` entry. Confirm the following settings (leave the generated `url`, `token`, and other values intact):

```toml
[[runners]]
  executor = "shell"
  shell = "powershell"
```

This is a **fragment**, not a replacement for the entire file. `powershell` uses Windows PowerShell; `pwsh` requires PowerShell 7 to be installed and available to the service account.

## Step 5 — Install and start the runner service

From **PowerShell as Administrator**:

```powershell
cd C:\GitLab-Runner
.\gitlab-runner.exe install
.\gitlab-runner.exe start
.\gitlab-runner.exe status
```

**Expected:** The service is running. In GitLab's runner page, the runner should become **online** after connecting. This can take a short time.

> For a first experiment, you can instead run `.\gitlab-runner.exe run` in a foreground terminal, but then the runner only works while that terminal remains open. The Windows service is the normal persistent option.

## Step 6 — Add the smallest GitLab pipeline

At the **root of your GitLab repository**, create `.gitlab-ci.yml`:

```yaml
stages:
  - test

hello_windows:
  stage: test
  tags:
    - windows-hello
  script:
    - 'Write-Output "Hello from Windows GitLab Runner!"'
```

Commit and push the file to a branch that is allowed to use your runner. No Rust or other build software is needed for this job.

**Why these lines?**

- `stages` declares a single stage named `test`.
- `hello_windows` is the job name.
- `tags` makes GitLab select a runner with the `windows-hello` tag.
- `script` runs a PowerShell command that prints the message.

## Step 7 — Verify in GitLab

1. Open **Build → Pipelines** (or **CI/CD → Pipelines**, depending on version).
2. Open the pipeline created by your commit.
3. Select the `hello_windows` job.
4. Inspect the job log.

**Expected result:**

```text
Hello from Windows GitLab Runner!
Job succeeded
```

The job should show **passed** (green). The exact surrounding log text varies by Runner version.

## Minimal troubleshooting

| Symptom | First check |
|---|---|
| Pipeline not created | `.gitlab-ci.yml` is committed at repository root; inspect CI lint and project pipeline settings |
| Job pending / stuck | Runner online, assigned to project, and tagged `windows-hello`; job branch compatible with protected-runner settings |
| Runner offline | Windows service running; GitLab URL reachable; token valid; inspect runner logs |
| `git` not found / checkout fails | Git installed and available in the **service account's** PATH |
| `Write-Output` fails / shell cannot start | `shell = "powershell"` in `config.toml`; PowerShell executable accessible |
| Access denied | Windows service identity and NTFS permissions |
| HTTPS certificate failure | Corporate proxy and trusted CA configuration; do **not** disable TLS validation |

### Optional local connectivity check

```powershell
cd C:\GitLab-Runner
.\gitlab-runner.exe verify
```

`verify` checks runner connectivity/registration state; it does **not** prove that the job script will succeed.

## Completion checklist

- [ ] GitLab Runner executable installed on Windows.
- [ ] Project runner created with tag `windows-hello`.
- [ ] Runner registered with its authentication token and `shell` executor.
- [ ] PowerShell selected and runner service running.
- [ ] `.gitlab-ci.yml` committed to the repository root.
- [ ] `hello_windows` job passed and printed the expected message.

**End state:** GitLab schedules the job → Windows Runner accepts it → PowerShell executes `Write-Output` → GitLab displays a successful job.

**Official references:** [Install GitLab Runner on Windows](https://docs.gitlab.com/runner/install/windows/) · [Register a runner](https://docs.gitlab.com/runner/register/) · [GitLab CI/CD YAML reference](https://docs.gitlab.com/ci/yaml/)
