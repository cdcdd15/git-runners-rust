# Windows GitLab Runner — Cargo Check (no Windows administrator rights)

**Goal:** Run one successful GitLab CI job executing `cargo check --locked` on a Windows PC, without Windows administrator rights, Windows service installation, or persistent changes to Windows environment variables.

**Approach:** Run GitLab Runner as a **normal foreground process** using the **Shell executor + Windows PowerShell**. Put its executable and configuration in your user-owned directory. Use existing Git and Cargo installations, or user-writable installations. Set `PATH` only for the **current PowerShell session**, if needed.

**Important distinction:** Windows administrator rights are normally needed to **install GitLab Runner as a Windows service**, not to download, register, or run it interactively. GitLab **project permissions** to create a runner are a separate requirement. Your organization may restrict executable downloads, runner registration, outbound network access, or software installation even when Windows itself does not require elevation.

## Prerequisites

- Windows user account with permission to run downloaded executables.
- GitLab project access to create a **project runner**, or an existing project runner assigned to the project. Depending on GitLab version/settings, creating a project runner generally requires Maintainer or equivalent permission.
- Git accessible to the same Windows user (existing installation or portable Git).
- Windows PowerShell (`powershell.exe`), typically built into Windows.
- Cargo and Rust available to the same user. The guide below avoids changes to persistent Windows environment variables.
- Access to GitLab and, if tools need to be downloaded, approved software distribution endpoints.

> **Security:** A Shell runner executes repository code with **your Windows account's permissions**. Use only a trusted test repository. Do not run untrusted merge requests or unrelated projects on this runner. Registration tokens are secrets.

## Step 1 — Prepare a user-owned runner directory

Open a **normal PowerShell window** (not “Run as administrator”):

```powershell
$RunnerDir = Join-Path $HOME 'gitlab-runner-lab'
New-Item -ItemType Directory -Force -Path $RunnerDir | Out-Null
Set-Location $RunnerDir
```

Download the official Windows amd64 GitLab Runner executable from the [GitLab Windows installation instructions](https://docs.gitlab.com/runner/install/windows/) and save it as:

```text
%USERPROFILE%\gitlab-runner-lab\gitlab-runner.exe
```

Verify:

```powershell
.\gitlab-runner.exe --version
```

**Expected:** A Runner version appears. **No admin rights or environment-variable changes.** The executable is invoked by its relative path, so it does not need to be added to `PATH`.

## Step 2 — Create a runner in GitLab

1. Open your GitLab project → **Settings → CI/CD → Runners** (the menu may vary by GitLab version).
2. Choose **Create project runner**.
3. Give it the tag `windows-cargo`; disable **Run untagged jobs**.
4. For a basic test on an ordinary branch, leave **Protected** disabled. This is for a trusted test project, not a recommendation for production.
5. Copy the runner authentication token (typically beginning `glrt-`). Do not put it in a Markdown file, commit, screenshot or job trace.

**Expected:** GitLab displays registration instructions and the runner authentication token.

**If your organization does not allow you to create a runner:** ask a GitLab Maintainer/administrator to create one for your project and provide an approved registration procedure. This is a **GitLab authorization** issue, not a Windows administrator issue.

## Step 3 — Register locally, without installing a service

In the **same normal PowerShell window**:

```powershell
Set-Location (Join-Path $HOME 'gitlab-runner-lab')
.\gitlab-runner.exe register --config .\config.toml
```

Enter the values when prompted:

| Prompt | Value |
|---|---|
| GitLab instance URL | Your real GitLab URL, e.g. `https://gitlab.example.com/` |
| Authentication token | Token from Step 2 |
| Executor | `shell` |
| Runner name/description, if requested | `windows-cargo-no-admin` |

**Expected:** Registration succeeds and `config.toml` is created in your user-owned folder. Modern GitLab runner tags are configured in GitLab when the runner is created, not through legacy registration-token options.

Inspect `config.toml`. Under the relevant `[[runners]]` section, set:

```toml
executor = "shell"
shell = "powershell"
```

Keep the other generated fields (`url`, `token`, etc.). **Do not replace the entire file with this fragment.** The explicit `powershell` setting avoids relying on PowerShell 7 (`pwsh`) being installed.

> Restrict access to `config.toml`: it contains sensitive runner authentication material. Do not commit it to Git.

## Step 4 — Check Git and Cargo without modifying Windows environment settings

First try the tools already installed:

```powershell
git --version
cargo --version
rustc --version
```

If all three work, **skip the rest of this step**. Because the runner will run as your user, it can usually inherit the environment from the PowerShell window where you start it.

### If Cargo exists but is not on PATH

For a conventional per-user rustup installation, Cargo may be at `$HOME\.cargo\bin`. Check the file and temporarily add that directory to **this PowerShell process only**:

```powershell
$CargoBin = Join-Path $HOME '.cargo\bin'
Test-Path (Join-Path $CargoBin 'cargo.exe')
$env:PATH = "$CargoBin;$env:PATH"
cargo --version
rustc --version
```

This changes only the current PowerShell process and its child processes. It does **not** edit user/system environment variables in Windows Settings, the registry, or other terminals. Closing the window removes this session-only change.

If Git is available as a portable executable but is not on PATH, similarly prepend its **actual** executable directory to `$env:PATH` for this session. Do not assume a particular installation directory.

### If Rust/Cargo is not installed — concrete no-admin installation

The usual Windows Rust installer is **rustup**, which installs and manages both the Rust compiler (`rustc`) and Cargo. By default, its files live inside your own Windows profile, so **Windows administrator rights are not inherently required**. This example intentionally avoids permanent user or system environment-variable changes.

**4A. Obtain the official installer.** In your browser, open [https://rustup.rs/](https://rustup.rs/) and follow its Windows download link. On a typical 64-bit Intel/AMD Windows PC, download the Windows x86-64 `rustup-init.exe` to your **Downloads** folder. On ARM64 Windows, use the appropriate supported installer/toolchain instead. In a corporate environment, use the company-approved source and confirm downloads/execution are permitted.

**4B. Install from a normal PowerShell window.** Run the installer from its actual downloaded location (adjust the path if your browser renamed or relocated it):

```powershell
$RustupInstaller = Join-Path $HOME 'Downloads\rustup-init.exe'
Test-Path $RustupInstaller
& $RustupInstaller -y --no-modify-path --default-toolchain stable
```

`Test-Path` should print `True` before running the next line. The `-y` flag accepts the installer's defaults; `--no-modify-path` prevents rustup from updating your persistent `PATH`; `--default-toolchain stable` selects the stable Rust toolchain. If the installer reports an error, resolve that error rather than assuming Rust was installed.

> **Windows C++ build tools:** The default Windows Rust toolchain commonly uses the MSVC target. Rustup may warn that Microsoft C++ build tools or a Windows SDK are missing. Installing those components can require administrator rights or IT assistance. For this minimal **`cargo check`** exercise, linking an executable is not required, so the check may succeed without a linker; later `cargo build`, `cargo run`, or tests can require additional native tooling. Do not treat a successful `cargo check` as proof that full native builds work.

**4C. Locate the installed files.** With rustup's default per-user locations:

```powershell
$CargoBin = Join-Path $HOME '.cargo\bin'
Test-Path (Join-Path $CargoBin 'cargo.exe')
Test-Path (Join-Path $CargoBin 'rustc.exe')
```

Both checks should return `True`. The Rust toolchains themselves are usually under `$HOME\.rustup\toolchains`; `.cargo\bin` contains the command launchers.

**4D. Make Cargo available in this PowerShell session only.**

```powershell
$env:PATH = "$CargoBin;$env:PATH"
cargo --version
rustc --version
rustup show active-toolchain
```

**Expected:** Cargo and rustc report versions, and rustup reports the active stable toolchain. This `PATH` adjustment exists **only in this PowerShell session and processes it starts**; it does not change Windows Settings, registry user/system PATH, or other terminal sessions.

**4E. Launch GitLab Runner from this same PowerShell session** using Step 5. Because the runner is a child process, it inherits the temporary `PATH`, and its PowerShell job can find Cargo. After closing the terminal, repeat the temporary `PATH` command before restarting the runner. You do **not** need to reinstall Rust each time.

**Alternative with no `PATH` change at all:** In your CI YAML, invoke Cargo by its full user-profile path (for example, `& "$HOME\.cargo\bin\cargo.exe" check --locked`) and similarly invoke rustc by full path if needed. The session-only `PATH` approach is simpler for the existing YAML and keeps it portable.

Installing Rust on a managed corporate machine can be restricted by policy even when Windows elevation is technically unnecessary. If your organization blocks downloads or execution, request an approved installation rather than bypassing controls.

**Expected:** `git --version`, `cargo --version` and `rustc --version` all work in the PowerShell window that will launch the runner.

## Step 5 — Start the runner as a normal process

Still in **the same PowerShell session** (so session-only `PATH` changes are inherited):

```powershell
Set-Location (Join-Path $HOME 'gitlab-runner-lab')
.\gitlab-runner.exe run --config .\config.toml --working-directory .
```

**Expected:** The runner stays running in the terminal, connects to GitLab, and appears **online** in the project's runner list. Leave this window open while testing.

**No `install`, `start`, or Windows service commands are used.** Press **Ctrl+C** to stop the runner. It will not run automatically after logout/reboot; repeat Step 5 when needed.

**If the process cannot reach GitLab:** check approved proxy/TLS/network configuration. Do not disable certificate verification.

## Step 6 — Create the minimal Rust project

In your GitLab repository, add:

```text
repository/
├── .gitlab-ci.yml
├── Cargo.toml
├── Cargo.lock
└── src/
    └── main.rs
```

**`Cargo.toml`**:

```toml
[package]
name = "hello_cargo_ci"
version = "0.1.0"
edition = "2021"

[dependencies]
```

**`src/main.rs`**:

```rust
fn main() {
    println!("Hello from Windows Cargo CI!");
}
```

Generate the lockfile **locally in the repository**:

```powershell
cargo generate-lockfile
```

**Expected:** `Cargo.lock` is created. This minimal project has no third-party dependencies.

## Step 7 — Add exactly one Cargo job

Create **`.gitlab-ci.yml`** at repository root:

```yaml
stages:
  - test

cargo_check_windows:
  stage: test
  tags:
    - windows-cargo
  script:
    - 'cargo --version'
    - 'rustc --version'
    - 'cargo check --locked'
    - 'if ($LASTEXITCODE -ne 0) { throw "Cargo check failed" }'
```

**What happens:** GitLab schedules the job → your foreground runner accepts it → Windows PowerShell runs Cargo → Cargo checks the project → the job passes if the command succeeds.

The job's tag must match the runner tag in GitLab. The runner must still be running in its terminal.

Commit and push the four files:

```powershell
git add .gitlab-ci.yml Cargo.toml Cargo.lock src/main.rs
git commit -m "ci: add minimal Windows Cargo check"
git push
```

**Expected:** One pipeline with one job is created.

## Step 8 — Verify the pipeline in GitLab

1. Open **Build → Pipelines** (or **CI/CD → Pipelines**).
2. Open the latest pipeline and click **`cargo_check_windows`**.
3. Confirm that the trace shows Cargo version information and a successful check.

Illustrative output:

```text
$ cargo --version
cargo 1.x.x (...)
$ rustc --version
rustc 1.x.x (...)
$ cargo check --locked
    Checking hello_cargo_ci v0.1.0 (...)
    Finished `dev` profile [unoptimized + debuginfo] target(s) in ...
Job succeeded
```

**Success condition:** `cargo check --locked` exits with code `0`, and GitLab reports **Job succeeded**. Exact versions, paths and timings will vary.

## Minimal troubleshooting

| Symptom | First check |
|---|---|
| Job pending | Foreground runner still open, online, correct project and `windows-cargo` tag |
| Runner stops after terminal closes | Expected: this is not a Windows service |
| `cargo` not recognized in CI | Start runner from the **same session** where Cargo's directory was added to `$env:PATH` |
| `git` not recognized | Git installed or portable Git executable directory added to session PATH |
| `pwsh` not found | Ensure `shell = "powershell"` in `config.toml` |
| `Cargo.toml` not found | Commit file at repository root and verify checkout |
| Lockfile error | Run `cargo generate-lockfile` and commit `Cargo.lock` |
| Access denied | Ensure runner folder and checkout directory are writable by your Windows account |
| GitLab registration denied | Check GitLab project role and runner creation policy |
| TLS/proxy failure | Diagnose the failing client; use approved CA/proxy configuration |

## Completion checklist

- [ ] No Windows administrator session was used.
- [ ] Runner executable and `config.toml` are in a user-owned folder.
- [ ] Runner is registered to the GitLab project with tag `windows-cargo`.
- [ ] Runner is started using `gitlab-runner.exe run`, **not** as a service.
- [ ] Git, Cargo and rustc are available in the runner's session.
- [ ] No persistent Windows user/system environment variables were modified by this procedure.
- [ ] The repository contains `Cargo.toml`, `Cargo.lock`, `src/main.rs` and `.gitlab-ci.yml`.
- [ ] The one-job GitLab pipeline succeeds.

## Differences from the Windows-service version

| Aspect | Previous guide | This guide |
|---|---|---|
| Windows administrator rights | Usually required for service installation | **Not required** |
| Runner execution | Windows service | Foreground user process |
| Windows service account | Separate identity possible | Your logged-in account |
| Persistent PATH changes | Sometimes needed for service toolchain | **Not required** |
| Startup after reboot | Can be automatic | Manual restart |
| Production suitability | Possible with proper hardening | **Learning/test setup only** |

**Official references:** [GitLab Runner Windows](https://docs.gitlab.com/runner/install/windows/) · [Runner registration](https://docs.gitlab.com/runner/register/) · [Runner commands](https://docs.gitlab.com/runner/commands/) · [GitLab CI YAML](https://docs.gitlab.com/ci/yaml/) · [Cargo check](https://doc.rust-lang.org/cargo/commands/cargo-check.html)
