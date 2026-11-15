# Nexus IQ / Sonatype Lifecycle — Windows GitLab Runner + Rust

**Scope:** Install scanner prerequisites on an existing Windows GitLab Shell runner (PowerShell), evaluate Rust dependencies via CycloneDX SBOM, and integrate a GitLab CI job. The IQ server is assumed to be remotely hosted.

## 1. Architecture and prerequisites

`GitLab → Windows Shell runner → cargo-cyclonedx → bom.json → Nexus IQ CLI → Nexus IQ Server (policy evaluation)`

Required: `rustc`, `cargo`, GitLab Runner with PowerShell executor, network/TLS access to IQ, an existing IQ application **public ID**, and a dedicated service account with *Evaluate applications* rights. The Windows Nexus IQ CLI distribution with a bundled JDK avoids requiring a separate Java installation.

## 2. Install and verify locally (PowerShell)

```powershell
rustc --version
cargo --version
Get-Command cargo
cargo install cargo-cyclonedx --locked
cargo cyclonedx --help
```

From the GitLab repository root (contains `Cargo.toml`):

```powershell
cargo cyclonedx --format json
Get-ChildItem -Recurse -Filter bom.json
```

**Note:** `cargo-cyclonedx` writes a BOM next to each relevant `Cargo.toml`, so Cargo workspaces can produce multiple `bom.json` files. Check the CLI version's supported flags if you need to limit the output.

Download the approved **Sonatype IQ CLI with bundled JDK for Windows** from the official Sonatype documentation and unzip under `C:\Tools\nexus-iq`. Find the `.bat` launcher; its path depends on distribution layout.

```powershell
$iqCli = 'C:\Tools\nexus-iq\bin\nexus-iq-cli.bat' # Adjust after extracting
Test-Path $iqCli
& $iqCli --help
Test-NetConnection iq.company.example -Port 443
```

If using the Java JAR distribution instead: `java -jar C:\Tools\nexus-iq\nexus-iq-cli.jar` (requires a compatible JDK).

## 3. GitLab variables

GitLab **Settings → CI/CD → Variables**:

| Variable | Example | Handling |
|---|---|---|
| `NEXUS_IQ_URL` | `https://iq.company.example` | Normal |
| `NEXUS_IQ_APP_ID` | `rust-demo` | Normal; IQ application **public ID** |
| `NEXUS_IQ_USER` | service-account user/token username | Mask if appropriate |
| `NEXUS_IQ_PASSWORD` | token password | **Masked**, restricted to authorized branches |

For sensitive CI variables, consider *Protected*, but remember protected variables are unavailable on unprotected branches. Never print credential variables. Use the IQ CLI's parameter-file / environment-variable capability when supported to avoid exposing authentication in a process command line; the sample below demonstrates the standard documented `-a` form for basic integration.

## 4. Local evaluation before CI

Set credentials in your PowerShell session **securely** (e.g., injected from an approved secret store), then:

```powershell
$ErrorActionPreference = 'Stop'
$iqCli = 'C:\Tools\nexus-iq\bin\nexus-iq-cli.bat'
$auth = "${env:NEXUS_IQ_USER}:${env:NEXUS_IQ_PASSWORD}"
& $iqCli -s $env:NEXUS_IQ_URL -i $env:NEXUS_IQ_APP_ID -a $auth '.\bom.json'
if ($LASTEXITCODE -ne 0) { throw 'Nexus IQ evaluation failed' }
```

Verify the report is attached to the expected IQ application and policy stage; test a known policy violation in a disposable test application to confirm CI gating behavior.

## 5. `.gitlab-ci.yml` snippet (PowerShell Shell executor)

Add `security` to your existing `stages:` array. Match runner tags to the **actual** tags registered in GitLab. Do not replace existing build/test jobs.

```yaml
nexus_iq_scan:
  stage: security
  tags: [windows, rust]
  script:
    - |
      $ErrorActionPreference = 'Stop'
      $cli = 'C:\Tools\nexus-iq\bin\nexus-iq-cli.bat'
      if (-not (Test-Path $cli)) { throw "Nexus IQ CLI missing: $cli" }

      cargo cyclonedx --format json
      if ($LASTEXITCODE -ne 0) { throw 'SBOM generation failed' }

      $boms = @(Get-ChildItem -Path . -Filter bom.json -Recurse -File)
      if ($boms.Count -eq 0) { throw 'No bom.json generated' }

      $auth = "${env:NEXUS_IQ_USER}:${env:NEXUS_IQ_PASSWORD}"
      foreach ($bom in $boms) {
        & $cli -s $env:NEXUS_IQ_URL -i $env:NEXUS_IQ_APP_ID -a $auth $bom.FullName
        if ($LASTEXITCODE -ne 0) {
          throw "Nexus IQ evaluation failed for $($bom.FullName)"
        }
      }
  artifacts:
    when: always
    paths:
      - '**/bom.json'
    expire_in: 7 days
```

**Caution:** The snippet evaluates each BOM separately. Multiple workspace BOMs will generate multiple evaluations for the same app, possibly making the last evaluation the most visible. For a production workspace, agree on a single aggregate SBOM/evaluation strategy rather than treating each workspace BOM as a complete application.

## 6. Verification matrix

| Check | PowerShell / location | Expected |
|---|---|---|
| Rust available | `cargo --version` | Version printed |
| SBOM tool available | `cargo cyclonedx --help` | Help printed |
| SBOM created | `Get-ChildItem -Recurse -Filter bom.json` | One or more BOMs |
| CLI installed | `Test-Path $iqCli` | `True` |
| IQ reachable | `Test-NetConnection iq.company.example -Port 443` | `TcpTestSucceeded: True` |
| Credentials accepted | Manual IQ CLI scan | Report generated |
| CI integration | GitLab pipeline | Security job executes |
| Policy enforcement | Controlled negative test | Policy-violating evaluation fails if configured to do so |

## 7. Troubleshooting

- **`cargo cyclonedx` not found:** verify `%USERPROFILE%\.cargo\bin` is visible to the GitLab Runner *service account*, not just your interactive login. Restart Runner service if its environment changed.
- **CLI path not found:** list extracted files with `Get-ChildItem C:\Tools\nexus-iq -Recurse -Filter '*.bat'` and update the path.
- **401/403:** service token wrong or no application evaluation permission. Keep server permissions separate from GitLab permissions.
- **TLS errors:** check corporate proxy and trusted CA/JDK truststore (bundled Java has its own truststore). Do not bypass TLS verification.
- **No dependency findings:** inspect BOM contents and IQ report; confirm CycloneDX support for the deployed IQ/CLI versions.
- **Job works interactively but fails in CI:** check Windows service account, filesystem access, PATH, and proxy settings.

## 8. References

- [Sonatype IQ CLI](https://help.sonatype.com/en/sonatype-iq-cli.html)
- [Sonatype CycloneDX application analysis](https://help.sonatype.com/en/cyclonedx.html)
- [cargo-cyclonedx](https://github.com/CycloneDX/cyclonedx-rust-cargo)
