# Windows GitLab Runner — minimal successful Cargo pipeline

**Goal:** Run one GitLab CI job on a Windows machine that successfully executes `cargo check --locked` for a tiny Rust project.

**Scope:** Windows 10/11 or Windows Server, GitLab Runner with **Shell** executor and Windows PowerShell, Git, and Rust/Cargo. No Docker, SonarQube, Nexus IQ, Fortify or release packaging.

**Starting point:** You can reuse the runner from the [Hello World guide](windows-gitlab-runner-hello-world.md). If that runner is already online, **skip Steps 1–4** and focus on installing Rust for its service account and committing the minimal project.

## Prerequisites

- Administrator rights on the Windows test machine.
- GitLab project access sufficient to create or use a project runner.
- Network access to GitLab; for initial Rust installation and dependency retrieval, appropriate access to approved Rust download/registry endpoints.
- Git installed and visible to the **runner service account**.
- Windows PowerShell (`powershell.exe`), or adapt the runner to `pwsh` if PowerShell 7 is installed.
- Rust toolchain and Cargo accessible to the **runner service account**.

> **Security:** A Shell runner executes repository code directly on the Windows host. Use a trusted test project and a dedicated machine/VM. For this learning exercise, no CI secret is required beyond the runner's own authentication.

## Step 1 — Download GitLab Runner (skip if already installed)

1. Create `C:\GitLab-Runner`.
2. Download the official Windows amd64 runner from [GitLab's Windows installation guide](https://docs.gitlab.com/runner/install/windows/).
3. Save the executable as `C:\GitLab-Runner\gitlab-runner.exe`.
4. In **PowerShell as Administrator**:

```powershell
cd C:\GitLab-Runner
.\gitlab-runner.exe --version
```

**Expected:** A Runner version is displayed.

## Step 2 — Create a project runner in GitLab

1. Open **Settings → CI/CD → Runners** in your project (menu names can vary).
2. Choose **Create project runner**.
3. Set tag **`windows-cargo`**, disable **Run untagged jobs**, and leave **Protected** off for a simple test on an ordinary branch.
4. Copy the generated runner authentication token (`glrt-...` on modern GitLab versions). Keep it secret.

**Expected:** GitLab displays a runner record and registration instructions.

> If reusing the Hello World runner, you can instead add `windows-cargo` to its tags in GitLab, or keep its original tag and change the YAML below to match.

## Step 3 — Register the runner

In administrator PowerShell:

```powershell
cd C:\GitLab-Runner
.\gitlab-runner.exe register
```

| Prompt | Value |
|---|---|
| GitLab URL | Your instance URL, e.g. `https://gitlab.example.com/` |
| Token | The runner authentication token from Step 2 |
| Executor | `shell` |
| Description | `windows-cargo-local` if requested |

**Expected:** Registration succeeds and `config.toml` is created. With modern runner authentication, configure tags in GitLab, not through legacy registration-token options.

## Step 4 — Configure and start the Windows service

Check the generated `C:\GitLab-Runner\config.toml`:

```toml
[[runners]]
  executor = "shell"
  shell = "powershell"
```

This is a **fragment**: do not overwrite the generated URL and token.

In administrator PowerShell:

```powershell
cd C:\GitLab-Runner
.\gitlab-runner.exe install
.\gitlab-runner.exe start
.\gitlab-runner.exe status
```

**Expected:** The service is running and the runner becomes **online** in GitLab.

If the service is already installed and running, do not reinstall it; confirm its status instead.

## Step 5 — Install Rust and verify Cargo for the runner account

1. Install the approved Rust toolchain on Windows using the organization's approved distribution method. For a personal test machine, see [rustup.rs](https://rustup.rs/).
2. Ensure the **runner service account**, not just your interactive Windows user, can execute `cargo.exe` and `rustc.exe`.
3. In an interactive PowerShell, verify the local installation:

```powershell
cargo --version
rustc --version
Get-Command cargo
```

**Expected:** Both tools report versions.

**Important:** Interactive success is not sufficient. A Windows service may run under `LocalSystem` or a dedicated account, whose `PATH` and `%USERPROFILE%` differ from yours. A typical per-user Rust installation puts `cargo.exe` under that user's `.cargo\bin` directory. Prefer a managed installation accessible to the runner identity; do not assume a developer-profile path works for the service.

For a minimal diagnostic, temporarily add `cargo --version` and `rustc --version` to the GitLab job below. That proves availability **inside the job's actual execution context**.

> If the service needs updated environment variables, restart it after changing the service environment according to your Windows administration policy.

## Step 6 — Add a minimal Rust project

At the root of the GitLab repository, create:

```text
your-repository/
├── .gitlab-ci.yml
├── Cargo.toml
├── Cargo.lock
└── src/
    └── main.rs
```

**`Cargo.toml`:**

```toml
[package]
name = "hello_cargo_ci"
version = "0.1.0"
edition = "2021"

[dependencies]
```

**`src/main.rs`:**

```rust
fn main() {
    println!("Hello from Cargo CI!");
}
```

Generate and commit the lockfile locally:

```powershell
cargo generate-lockfile
git add Cargo.toml Cargo.lock src/main.rs
```

**Expected:** `Cargo.lock` exists. This project has **no external dependencies**, so the first successful Cargo check does not depend on downloading third-party crates.

`cargo check` type-checks and compiles enough of the crate to validate it without producing the normal runnable executable. It is a meaningful, fast first Cargo goal.

## Step 7 — Add the one-job GitLab pipeline

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

**Why these lines?**

- `stages: [test]` (written as a YAML list above) defines one stage.
- `cargo_check_windows` is the only job.
- `tags` selects the runner with tag `windows-cargo`.
- `cargo --version` and `rustc --version` verify the actual service environment.
- `cargo check --locked` validates the Rust crate while refusing to modify an out-of-date lockfile.
- `$LASTEXITCODE` checks the native executable's exit status; a nonzero result explicitly fails the job.

Commit and push:

```powershell
git add .gitlab-ci.yml
git commit -m "ci: add minimal Windows Cargo check"
git push
```

**Expected:** GitLab creates a pipeline with one job.

## Step 8 — Verify the result in GitLab

1. Open **Build → Pipelines** (or **CI/CD → Pipelines**).
2. Select the pipeline from your push.
3. Open **`cargo_check_windows`**.
4. Read the job trace.

**Illustrative successful output:**

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

Versions, paths, timings and surrounding Runner messages will vary. **The success condition is that `cargo check --locked` exits with code 0 and the GitLab job passes.**

## Minimal troubleshooting

| Symptom | First check |
|---|---|
| Job pending | Runner online, assigned to project, tag `windows-cargo`, correct protected-ref setting |
| `cargo` not recognized | Rust installed for/accessible to the **service account**, service PATH refreshed |
| `rustc` not recognized | Rust toolchain installation and executable PATH |
| `Cargo.toml` not found | File committed at repository root; job checkout succeeds |
| Lockfile needs updating | Generate and commit `Cargo.lock`; check manifest changes |
| Git checkout fails | Git availability, repository permissions, TLS and proxy |
| Cargo fails fetching dependencies | Registry connectivity/proxy/certificates; this example has no external crates |
| Access denied in `target` | Service identity, Windows ACLs and workspace ownership |
| Job shows success despite an earlier error | Review PowerShell error propagation and explicit `$LASTEXITCODE` checks |

### Optional runner connectivity check

```powershell
cd C:\GitLab-Runner
.\gitlab-runner.exe verify
```

`verify` checks registration/connectivity; it does **not** prove Cargo is installed or that the job succeeds.

## Completion checklist

- [ ] Runner is installed, registered and online on Windows.
- [ ] Runner has the `windows-cargo` tag.
- [ ] Runner uses Shell executor with PowerShell.
- [ ] `cargo` and `rustc` are visible **inside the CI job**.
- [ ] `Cargo.toml`, `Cargo.lock` and `src/main.rs` are committed.
- [ ] `.gitlab-ci.yml` has one `cargo_check_windows` job.
- [ ] GitLab job finishes successfully with `cargo check --locked`.

**End state:** GitLab schedules the job → Windows Runner accepts it → PowerShell starts Cargo → Cargo validates the Rust crate → GitLab displays **Job succeeded**.

**Next optional goal:** Replace `cargo check --locked` with `cargo test --locked` to run a first Rust unit test, or use `cargo build --locked` to produce a binary.

**Official references:** [Windows Runner installation](https://docs.gitlab.com/runner/install/windows/) · [Runner registration](https://docs.gitlab.com/runner/register/) · [GitLab CI YAML](https://docs.gitlab.com/ci/yaml/) · [Cargo check](https://doc.rust-lang.org/cargo/commands/cargo-check.html)
