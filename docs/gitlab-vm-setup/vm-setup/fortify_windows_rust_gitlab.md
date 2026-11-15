# OpenText Fortify SAST — Windows GitLab Runner + Rust

**Scope:** Install and validate Fortify CLI / ScanCentral SAST Client on an existing Windows GitLab Shell runner, then submit a scan from `.gitlab-ci.yml`. Assumes **Software Security Center (SSC) + ScanCentral SAST**; **Fortify on Demand** requires another workflow.

> **Rust gate:** First obtain confirmation from the Fortify administrator that the *specific licensed sensor/version and scanning workflow* support Rust (possibly via AI-powered SAST). A successful upload of Rust sources does **not** prove they were analyzed. Do not treat this as production-ready until the server produces findings/coverage for `.rs` files.

## 1. Architecture

`GitLab → Windows PowerShell runner → fcli + ScanCentral Client → source package → ScanCentral Controller/Sensors → SSC findings`

The server/controller/sensor infrastructure usually runs remotely. You install the **clients**, not SSC itself, on Windows.

## 2. Confirm with Fortify administrator

Obtain:

1. SSC base URL, application/version name (often `application:version`) and CI authentication token.
2. ScanCentral SAST availability, sensor pool and compatible ScanCentral Client version.
3. Rust scanner support, required SAST mode and translation/packaging commands for your version.
4. Permission to send source code to the remote scanners under corporate classification policy.
5. Security gate criteria: severity thresholds, scan completion timeout and findings policy.

## 3. Install Fortify CLI (`fcli`) on Windows

Download a company-approved Windows executable or package from [Fortify CLI releases](https://github.com/fortify/fcli/releases), unpack under `C:\Tools\fortify\fcli`, and locate `fcli.exe` or the provided launcher.

```powershell
$fcli = 'C:\Tools\fortify\fcli\fcli.exe' # Adjust if needed
Test-Path $fcli
& $fcli --version
& $fcli --help
Test-NetConnection ssc.company.example -Port 443
```

Use the local help for the installed `fcli` major version; syntax changes between releases.

## 4. GitLab variables

At **Settings → CI/CD → Variables**:

| Variable | Purpose | Handling |
|---|---|---|
| `FORTIFY_SSC_URL` | e.g. `https://ssc.company.example` | Normal |
| `FORTIFY_SSC_TOKEN` | SSC automation token | Masked / protected as appropriate |
| `FORTIFY_APP_VERSION` | e.g. `rust-demo:main` | Normal |
| `FORTIFY_SENSOR_VERSION` | sensor version for scan submission | Normal |
| `FORTIFY_CLIENT_VERSION` | compatible ScanCentral Client version | Normal |

Use a runner/service identity authorized for scanning and limit token lifetime/scopes according to organizational policy.

## 5. Authenticate, inspect sensors, install ScanCentral Client

Inject the `FORTIFY_*` environment variables securely, then:

```powershell
$fcli = 'C:\Tools\fortify\fcli\fcli.exe'

& $fcli ssc session login --url=$env:FORTIFY_SSC_URL --token=$env:FORTIFY_SSC_TOKEN
if ($LASTEXITCODE -ne 0) { throw 'SSC login failed' }

& $fcli sc-sast sensor list --latest-only
if ($LASTEXITCODE -ne 0) { throw 'Sensor query failed' }

# Install the client version recommended as compatible with your sensor.
# Substitute an actual version returned/approved by your administrator.
& $fcli tool sc-client install -v $env:FORTIFY_CLIENT_VERSION -y
if ($LASTEXITCODE -ne 0) { throw 'Client installation failed' }

& $fcli tool sc-client run -v $env:FORTIFY_CLIENT_VERSION -- package -h
& $fcli ssc session logout
```

**Important:** Sensor version and **compatible client version** are not always literally the same string. Use `FORTIFY_CLIENT_VERSION` for local packaging and `FORTIFY_SENSOR_VERSION` for remote scanning.

## 6. Prepare a Rust source package — validate on your platform

For a generic source package, the baseline command is:

```powershell
& $fcli tool sc-client run -v $env:FORTIFY_CLIENT_VERSION -- package -o fortify-package.zip
if ($LASTEXITCODE -ne 0) { throw 'Packaging failed' }
Test-Path '.\fortify-package.zip'
```

For Rust, **this may not be the correct packaging/translation approach** for your deployed sensor. Ask the administrator for the supported Rust/AI-powered SAST command and confirm actual `.rs` inclusion and analysis. Do not pretend generic packaging implies supported Rust scanning.

## 7. Submit a scan and wait for completion

Example for `fcli` 3.x-style `sc-sast scan start` syntax (verify `-h` in your installed version):

```powershell
& $fcli sc-sast scan start `
  --file='fortify-package.zip' `
  --sensor-version=$env:FORTIFY_SENSOR_VERSION `
  --publish-to=$env:FORTIFY_APP_VERSION `
  --store=rustScan
if ($LASTEXITCODE -ne 0) { throw 'Scan submission failed' }

& $fcli sc-sast scan wait-for '::rustScan::'
if ($LASTEXITCODE -ne 0) { throw 'Scan did not complete successfully' }
```

Check the SSC application version for published results and language coverage. **Waiting for completion is not equivalent to enforcing a findings policy.** Define a separate policy/gate step with the supported SSC CI action or audited organization-specific rules.

## 8. `.gitlab-ci.yml` snippet (PowerShell Shell executor)

Add `security` to `stages`, then adapt tags and paths. The runner must have `fcli` and compatible `sc-client` installed. Configure both `FORTIFY_CLIENT_VERSION` and `FORTIFY_SENSOR_VERSION` in GitLab variables.

```yaml
fortify_sast_scan:
  stage: security
  tags: [windows, rust]
  script:
    - |
      $ErrorActionPreference = 'Stop'
      $fcli = 'C:\Tools\fortify\fcli\fcli.exe'
      if (-not (Test-Path $fcli)) { throw "fcli missing: $fcli" }

      try {
        & $fcli ssc session login `
          --url=$env:FORTIFY_SSC_URL `
          --token=$env:FORTIFY_SSC_TOKEN
        if ($LASTEXITCODE -ne 0) { throw 'SSC login failed' }

        # Replace this packaging command with the approved Rust workflow
        # if your Fortify version requires different analysis preparation.
        & $fcli tool sc-client run `
          -v $env:FORTIFY_CLIENT_VERSION -- `
          package -o fortify-package.zip
        if ($LASTEXITCODE -ne 0) { throw 'Packaging failed' }

        & $fcli sc-sast scan start `
          --file='fortify-package.zip' `
          --sensor-version=$env:FORTIFY_SENSOR_VERSION `
          --publish-to=$env:FORTIFY_APP_VERSION `
          --store=rustScan
        if ($LASTEXITCODE -ne 0) { throw 'Scan submission failed' }

        & $fcli sc-sast scan wait-for '::rustScan::'
        if ($LASTEXITCODE -ne 0) { throw 'Scan failed or timed out' }

        Write-Host 'Fortify scan complete. Policy gate must be checked separately.'
      }
      finally {
        & $fcli ssc session logout
      }
```

**Token-lifetime warning:** Fortify may need a long-lived publishing token if the SSC session ends before scan publication; keeping the session active through `wait-for` helps but does not substitute for your platform's token rules. For multi-tenant/shared runners, isolate Fortify session configuration/state per job, using the mechanisms documented for your installed CLI version.

Do **not** publish the ZIP source package as an ordinary GitLab artifact without explicit approval.

## 9. Security gate (production follow-up)

A production integration should: (1) successfully analyze Rust source; (2) await completion; (3) publish findings into SSC; (4) enforce an approved fail/pass condition. Fortify provides an [SSC CI action](https://fortify.github.io/fcli/latest/ssc-actions.html) that can orchestrate packaging, scanning, waiting and policy checks. Prefer the audited action for your platform over inventing a custom severity filter. Run `fcli ssc action run ci -h` and validate its required environment variables in your version.

## 10. Verification and troubleshooting

| Check | Validation | Expected |
|---|---|---|
| `fcli` exists | `& $fcli --version` | Version printed |
| SSC reachable | `Test-NetConnection ... -Port 443` | TCP succeeds |
| SSC token works | `ssc session login` | Login succeeds |
| Sensors listed | `sc-sast sensor list` | Compatible sensor available |
| Client installed | `tool sc-client ... package -h` | Help printed |
| Rust source packaged | Inspect package contents and server logs | `.rs` files present and recognized |
| Scan submitted | `sc-sast scan start` | Scan ID/job token returned |
| Scan completed | `scan wait-for` | Success |
| Findings published | SSC app/version | Correct project + Rust coverage |
| Gate enforced | Controlled negative test | Pipeline fails for disallowed findings |

Common problems: auth failure (token type/permissions); client/sensor incompatibility; TLS/proxy/truststore; invalid `application:version`; package contains source but sensor skips Rust; successful submission but failed asynchronous publishing; Windows service account lacks access to tools/working directories.

## 11. References

- [Fortify CLI downloads](https://github.com/fortify/fcli/releases)
- [Fortify CLI documentation](https://fortify.github.io/fcli/latest/)
- [Fortify SAST scan command](https://fortify.github.io/fcli/v3.29.1/manpage/fcli-sc-sast-scan-start.html)
- [Fortify SSC CI actions](https://fortify.github.io/fcli/latest/ssc-actions.html)
- [Fortify ScanCentral Client setup guide](https://github.com/fortify/skills/blob/main/skills/fcli-common/references/fcli-install.md)
