# P6.2 · Diagnose a Windows service-context failure

**Access** — Offline. Read [Windows Shell Runner concepts](../concepts/windows-shell-runner.md) and [P6.1](p6-1-review-windows-runner-setup.md) first. All configuration, traces and fixes are illustrative and unexecuted.

Ledger Gateway's release job runs on a Windows Shell runner. The administrator can build in an interactive terminal, but the service job fails. Three successive traces show how an initial failure can hide the next one. For each trace, name the last successful boundary, the narrowest correction, and the evidence that would confirm recovery.

## A · Tool lookup under the service identity

```text
Runner: ledger-release-windows; executor: shell; shell: pwsh
Checkout: succeeded
PowerShell: 7.x
whoami: CORP\svc-ledger-runner
Get-Command cargo: command not found
Administrator terminal: cargo resolves under C:\Users\admin\.cargo\bin
```

**Worked diagnosis** — The job was assigned, checked out sources and started PowerShell. Cargo has not started, so the failure is executable lookup. Compare the service job's account, effective PATH, approved Cargo location and access to the toolchain. The administrator's user-local shim does not establish any of those. Have the host owner make the approved toolchain available to the service and refresh its process environment through the managed service procedure. Recovery evidence is `Get-Command cargo` resolving to the approved executable and `rustc -vV` showing the expected toolchain. Confirm a native build separately because finding Cargo does not establish linker or SDK availability.

## B · Registry TLS after Cargo starts

```text
Checkout: succeeded
Cargo executable: C:\Build Tools\Rust\bin\cargo.exe
Cargo: updating corporate-mirror index
Cargo: TLS certificate validation failed at https://cargo-mirror.example.invalid/index/config.json
Runner connectivity check against GitLab: passed
```

**Worked diagnosis** — Command lookup now succeeds and Cargo reaches its own registry operation. The earlier GitLab connectivity check does not test this HTTPS client or endpoint. Review the effective [Cargo source replacement](p2-1-read-cargo-manifests-and-lockfile.md), then inspect the certificate chain and proxy route seen by Cargo in the service context. An approved CA bundle can be supplied through Cargo's HTTP configuration when appropriate. If the CA is delivered as a [GitLab file variable](p4-2-review-secret-and-scope-boundaries.md), the environment variable contains the path to the bundle. Keep verification enabled. Recovery evidence is a locked fetch from the intended mirror with TLS validation succeeding, followed by successful authorization if required.

## C · Compilation failed but collection continued

In a separate observed variation of the repaired job, a helper script captures a native exit code but logs it and proceeds. The checkout path has spaces. The collected executable may be left over from an earlier build.

```text
Checkout: D:\Runner Builds\platform\ledger-gateway
cargo build: linker link.exe not found
Captured native exit: 101
Collection: copied existing dist/ledger-route.exe
```

**Worked diagnosis** — Cargo started and reached compilation, but the native linker was unavailable. Review the service account's MSVC and SDK configuration. Separately correct the helper's control flow so no copy can run after a failed build. If Cargo succeeds but collection still fails, check the target triple, profile and resolved source path before changing the toolchain.

The following PowerShell excerpt assumes the job has already resolved the approved toolchain, and any existing distribution folder is governed by the project's workspace cleanup policy. It uses literal paths and only stages the expected output after the successful native invocation.

```powershell
Set-Location -LiteralPath $env:CI_PROJECT_DIR -ErrorAction Stop
$cargo = Get-Command cargo -CommandType Application -ErrorAction Stop |
    Select-Object -First 1
& $cargo.Source build --locked -p ledger-route --release --target x86_64-pc-windows-msvc
$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) { exit $exitCode }

$binary = Join-Path $env:CI_PROJECT_DIR 'target/x86_64-pc-windows-msvc/release/ledger-route.exe'
$dist = Join-Path $env:CI_PROJECT_DIR 'dist'
New-Item -ItemType Directory -Path $dist -Force -ErrorAction Stop | Out-Null
Copy-Item -LiteralPath $binary -Destination (Join-Path $dist 'ledger-route.exe') -ErrorAction Stop
```

PowerShell's call operator invokes the resolved executable even when its path contains spaces. A terminating native error also stops the excerpt before collection. The producer should upload on success and a downstream release consumer should check the expected revision as in [P5.2](p5-2-trace-artifacts-and-dependency-edges.md).

## Review questions

1. **A developer substitutes Windows PowerShell for PowerShell Core. What evidence do you need?** Compare the configured shell and job trace, including the version, native argument behavior and encoding assumptions. A command that works interactively under a different shell is weak evidence.
2. **The executable exists in the runner's workspace. Can the release proceed after a linker error?** No. An old file does not prove a successful build for this commit. Correct the linker environment, propagate failure and verify a successful artifact handoff from the intended producer.
3. **A test fixture passes with LF but fails with CRLF. What do you inspect?** Check the input bytes and the tool's contract. For the parser in [P1.1](p1-1-read-a-rust-library-and-cli.md), either trailing line ending is accepted, though byte counts differ. Check encoding and embedded newlines before normalizing the input.

## Acceptance

For all three traces, identify the failing component, explain which prior boundary succeeded, propose a correction and name the recovery evidence. Explain why a successful GitLab connectivity check, an administrator's terminal and a file found on disk are insufficient for the three respective failures. Runtime work remains in [Future labs](../../FUTURE-LABS.md).
