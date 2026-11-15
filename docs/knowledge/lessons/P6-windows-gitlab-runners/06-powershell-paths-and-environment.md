# PowerShell, paths and the CI environment

## PowerShell is not Bash

A Windows Shell runner may use Windows PowerShell (`powershell`) or PowerShell 7+ (`pwsh`), depending on its configuration. GitLab Runner generates a script for the chosen shell. YAML examples written for Linux frequently fail because they assume `export`, `/tmp`, `chmod`, POSIX quoting or Bash exit semantics.

## Environment access

```powershell
Write-Host "Checkout: $env:CI_PROJECT_DIR"
Write-Host "Branch: $env:CI_COMMIT_REF_NAME"
$manifest = Join-Path $env:CI_PROJECT_DIR 'Cargo.toml'
if (-not (Test-Path $manifest)) {
    throw "Cargo manifest not found: $manifest"
}
```

Use `$env:NAME` to read CI variables. `Join-Path` avoids fragile manual concatenation. Quote paths containing spaces. Avoid printing protected secrets; masked values are not a guarantee against every form of disclosure.

## Native executable failures

PowerShell cmdlets often signal errors differently from external programs. For native tools such as Cargo or scanners, explicitly examine exit status when the surrounding script requires it.

```powershell
cargo test --locked
if ($LASTEXITCODE -ne 0) {
    throw "Cargo tests failed with exit code $LASTEXITCODE"
}
```

The behavior of error propagation can differ across PowerShell versions and GitLab Runner-generated scripts. An explicit check improves readability, especially when commands are wrapped or combined.

## Shell differences

| Topic | Bash | PowerShell |
|---|---|---|
| Read variable | `$CI_PROJECT_DIR` | `$env:CI_PROJECT_DIR` |
| Set process variable | `export NAME=value` | `$env:NAME = 'value'` |
| Path composition | `path/to/file` | `Join-Path $base 'file'` |
| Failure convention | Exit status | Cmdlet errors and `$LASTEXITCODE` |

## Working directory and quoting

A runner sets up a project checkout, typically exposed as `CI_PROJECT_DIR`. Relative paths in `.gitlab-ci.yml` should be interpreted in the job's workspace. A Windows service account may have a different home directory from the developer. Do not rely on `~` or user-profile-specific Cargo locations without checking the service identity.

```yaml
check_windows:
  tags: [windows, rust]
  script:
    - '$manifest = Join-Path $env:CI_PROJECT_DIR "Cargo.toml"'
    - 'if (-not (Test-Path $manifest)) { throw "Missing Cargo.toml" }'
    - 'cargo check --locked'
    - 'if ($LASTEXITCODE -ne 0) { throw "cargo check failed" }'
```

The example presumes PowerShell is configured for the runner and Rust is available on PATH.

## Encoding and line endings

Scripts, generated files and scanner inputs can be sensitive to encoding and CRLF/LF line endings. Avoid blindly converting files across platforms. When a scanner reports malformed input, inspect file encoding and command-line argument quoting before assuming a source-code problem.

## Troubleshooting sequence

Check the configured shell, `Get-Command cargo`, `$env:PATH`, working directory, tool version, effective account and native exit code. A pipeline that starts but fails at the first command is an execution-context problem, not a scheduling problem.

**Conclusion:** Treat shell syntax and service environment as explicit runtime dependencies.
