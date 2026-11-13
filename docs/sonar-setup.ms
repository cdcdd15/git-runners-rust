
# SonarScanner CLI — Windows GitLab Runner Setup & Validation

## 1. Objective

Install, configure, and validate SonarScanner CLI for a Rust/Cargo project running through a Windows GitLab Runner.

The setup must support:
- Windows Shell executor using PowerShell.
- Installation without administrator rights.
- No mandatory system environment variable changes.
- Validation before introducing the Sonar analysis job.
- SonarQube server connectivity and authentication.
- Quality Gate validation in GitLab CI/CD.

The implementation is divided into three phases:

| Phase | Objective | Expected result |
|---|---|---|
| P1 | Verify or install SonarScanner locally | CLI executable works |
| P2 | Validate SonarScanner inside GitLab CI/CD | Runner can execute scanner |
| P3 | Connect to SonarQube and analyze Cargo project | Quality Gate controls job result |

---

## 2. Prerequisites

| Component | Required | Validation |
|---|---|---|
| Windows machine | Yes | `whoami` |
| GitLab Runner | Yes | Runner online in GitLab UI |
| Shell executor | Yes | Check `config.toml` |
| PowerShell | Yes | `$PSVersionTable` |
| Java/JDK | Depends on scanner distribution | `java -version` |
| Rust/Cargo | Yes | `cargo --version` |
| Clippy | Recommended | `cargo clippy --version` |
| SonarScanner CLI | Yes | `sonar-scanner.bat -v` |
| SonarQube server | P3 | Server URL accessible |
| Sonar token | P3 | Valid authentication token |

### 2.1 Verify GitLab Runner

Open PowerShell:

~~~powershell
gitlab-runner --version
~~~

Locate `config.toml`.

For a user-mode Windows Runner, it is normally in the Runner working directory. For a service installation, inspect the Runner installation and service configuration.

Expected configuration:

~~~toml
[[runners]]
  name = "windows-runner"
  executor = "shell"
  shell = "powershell"
~~~

The runner must be registered and online in GitLab.

Check:

Project -> Settings -> CI/CD -> Runners

---

# PHASE P1 — Local SonarScanner Verification and Installation

## 3. Check whether SonarScanner is installed

Execute on the Windows machine hosting GitLab Runner:

~~~powershell
Get-Command sonar-scanner.bat -ErrorAction SilentlyContinue
~~~

Alternative:

~~~powershell
where.exe sonar-scanner.bat
~~~

If installed and available through PATH, the expected output resembles:

~~~text
C:\Tools\sonar-scanner\bin\sonar-scanner.bat
~~~

Validate the executable:

~~~powershell
sonar-scanner.bat -v
~~~

Check CLI help:

~~~powershell
sonar-scanner.bat -h
~~~

Expected result:
- The command executes.
- SonarScanner version information is displayed.
- No command-not-found errors occur.

If the command fails because the executable cannot be found, proceed to installation.

---

## 4. Install SonarScanner without administrator rights

### Step 4.1 — Download distribution

Official documentation:

https://docs.sonarsource.com/sonarqube-server/analyzing-source-code/scanners/sonarscanner/

Download the appropriate Windows ZIP distribution.

Prefer a distribution containing a bundled Java runtime, if compatible with your SonarQube server.

### Step 4.2 — Extract archive

Extract to a writable user directory:

~~~text
C:\Users\<username>\Tools\sonar-scanner\
~~~

Expected structure:

~~~text
sonar-scanner/
├── bin/
│   └── sonar-scanner.bat
├── conf/
│   └── sonar-scanner.properties
├── lib/
└── ...
~~~

Depending on the release, additional directories may exist.

Administrator privileges are not required for extraction into your own user directory.

### Step 4.3 — Verify using absolute path

~~~powershell
& "C:\Users\<username>\Tools\sonar-scanner\bin\sonar-scanner.bat" -v
~~~

Replace `<username>` with the actual Windows account folder.

Expected: SonarScanner version information.

This method does not require updating PATH or JAVA_HOME.

### Step 4.4 — Optional temporary PATH configuration

For the current PowerShell session:

~~~powershell
$env:PATH = "C:\Users\<username>\Tools\sonar-scanner\bin;" + $env:PATH
~~~

Validate:

~~~powershell
sonar-scanner.bat -v
~~~

Important:
- This PATH change is temporary.
- It applies only to the current PowerShell process and its children.
- A GitLab Runner service will not automatically inherit it.
- For no-admin environments, using an absolute executable path is often simpler.

---

# PHASE P2 — GitLab CI/CD Scanner Verification

## 5. Why local validation is insufficient

Successfully executing SonarScanner in a local PowerShell window does not guarantee that GitLab Runner can execute it.

Possible differences:

| Area | Local PowerShell | GitLab Runner |
|---|---|---|
| Windows user | Developer | Runner service account |
| PATH | User environment | Runner process environment |
| Directory permissions | Developer access | Runner account access |
| Java configuration | Developer JAVA_HOME | Runner Java configuration |
| Network access | Interactive session | Service environment |

Consequently, SonarScanner must be validated inside an actual GitLab pipeline.

---

## 6. Minimal GitLab verification job

Before modifying the existing Cargo build and test jobs, add a temporary verification stage.

If `stages` already exists, append `verify_tools` to the existing list instead of replacing it.

Example:

~~~yaml
stages:
  - verify_tools
  - build
  - test
~~~

Verification job:

~~~yaml
verify_sonar_scanner:
  stage: verify_tools
  tags:
    - windows

  script:
    - |
      Write-Host "=== SonarScanner verification ==="

      Write-Host "Runner account:"
      whoami

      Write-Host "Checking executable..."
      $scanner = Get-Command sonar-scanner.bat -ErrorAction SilentlyContinue

      if (-not $scanner) {
        throw "SonarScanner CLI not found in PATH"
      }

      Write-Host "Scanner path: $($scanner.Source)"

      & $scanner.Source -v

      if ($LASTEXITCODE -ne 0) {
        throw "SonarScanner execution failed"
      }

      Write-Host "SonarScanner verification PASSED"

  allow_failure: false
~~~

Replace the `windows` tag with your actual runner tag.

### Expected result

GitLab:

CI/CD -> Pipelines -> Job logs

Expected output:

~~~text
=== SonarScanner verification ===
Runner account:
...
Checking executable...
Scanner path: C:\Tools\sonar-scanner\bin\sonar-scanner.bat
SonarScanner CLI ...
SonarScanner verification PASSED
Job succeeded
~~~

If successful, GitLab Runner can execute SonarScanner.

---

## 7. Alternative: absolute path in pipeline

Use this method when SonarScanner is installed but not registered in PATH.

~~~yaml
verify_sonar_scanner:
  stage: verify_tools
  tags:
    - windows

  script:
    - |
      $scanner = "C:\Users\<username>\Tools\sonar-scanner\bin\sonar-scanner.bat"

      if (-not (Test-Path $scanner)) {
        throw "SonarScanner executable missing: $scanner"
      }

      & $scanner -v

      if ($LASTEXITCODE -ne 0) {
        throw "SonarScanner failed"
      }

      Write-Host "SonarScanner verification PASSED"

  allow_failure: false
~~~

Advantages:
- No administrator rights required.
- No permanent PATH modification required.
- Explicit executable location.
- Easier diagnosis in restricted enterprise environments.

The GitLab Runner account must have permission to read and execute the installation files.

---

# PHASE P3 — SonarQube Server and Cargo Analysis

## 8. Configure GitLab CI/CD variables

Navigate to:

Project -> Settings -> CI/CD -> Variables

Create:

| Variable | Description | Recommended handling |
|---|---|---|
| SONAR_HOST_URL | SonarQube server URL | Normal variable |
| SONAR_TOKEN | SonarQube authentication token | Masked and hidden |
| SONAR_PROJECT_KEY | SonarQube project identifier | Normal variable |

Example values:

~~~text
SONAR_HOST_URL=https://sonarqube.company.com
SONAR_PROJECT_KEY=rust-cargo-project
~~~

Do not commit the token to Git.

The token must be valid and authorized to execute analysis for the target project.

Protected variables are only made available to eligible protected refs. Validate the branch configuration when troubleshooting missing variables.

---

## 9. Validate SonarQube connectivity

First test server connectivity from the runner machine:

~~~powershell
Invoke-RestMethod `
  -Uri "https://sonarqube.company.com/api/server/version"
~~~

Replace the URL with your actual SonarQube endpoint.

Expected: server version information.

The endpoint confirms server connectivity but does not validate permissions for a project analysis.

### Validate authentication

~~~powershell
$headers = @{
    Authorization = "Bearer $env:SONAR_TOKEN"
}

Invoke-RestMethod `
  -Uri "$env:SONAR_HOST_URL/api/authentication/validate" `
  -Headers $headers
~~~

Expected response:

~~~json
{"valid":true}
~~~

This requires the variables to be available in the current PowerShell process.

A token stored in GitLab project variables is automatically injected into eligible CI jobs, not into arbitrary local terminals.

---

## 10. GitLab server connectivity verification job

Add a temporary job to the existing `verify_tools` stage:

~~~yaml
verify_sonar_connection:
  stage: verify_tools
  tags:
    - windows

  script:
    - |
      if (-not $env:SONAR_HOST_URL) {
        throw "SONAR_HOST_URL is missing"
      }

      if (-not $env:SONAR_TOKEN) {
        throw "SONAR_TOKEN is missing"
      }

      $baseUrl = $env:SONAR_HOST_URL.TrimEnd('/')

      Write-Host "Checking SonarQube connectivity..."

      $version = Invoke-RestMethod `
        -Uri "$baseUrl/api/server/version"

      Write-Host "SonarQube server version: $version"

      $headers = @{
        Authorization = "Bearer $env:SONAR_TOKEN"
      }

      $auth = Invoke-RestMethod `
        -Uri "$baseUrl/api/authentication/validate" `
        -Headers $headers

      if (-not $auth.valid) {
        throw "SonarQube authentication failed"
      }

      Write-Host "SonarQube connectivity PASSED"
      Write-Host "SonarQube authentication PASSED"

  allow_failure: false
~~~

Expected:
- SonarQube server reachable.
- Authentication token valid.
- GitLab job succeeds.

This is not yet proof that the token has sufficient analysis permissions.

---

## 11. Validate Cargo and Clippy

On the Windows Runner:

~~~powershell
cargo --version
~~~

~~~powershell
cargo clippy --version
~~~

If Clippy is missing:

~~~powershell
rustup component add clippy
~~~

Execute a local check inside the Rust project:

~~~powershell
cargo clippy --all-targets
~~~

Expected:
- Cargo dependencies resolve.
- Rust project compiles for Clippy analysis.
- Clippy executes successfully.

Note: Clippy warnings do not necessarily result in a nonzero exit code unless configured as errors.

Depending on the SonarQube version, Rust analysis may invoke Clippy automatically. Verify compatibility with your server's Rust analyzer.

---

## 12. Final SonarQube analysis stage

Once scanner verification and server connectivity succeed, introduce the actual Sonar analysis job.

Add `sonar` to the existing stages:

~~~yaml
stages:
  - build
  - test
  - sonar
~~~

If you retain the temporary verification jobs, also keep their `verify_tools` stage.

Final job:

~~~yaml
sonar_validation:
  stage: sonar
  tags:
    - windows

  variables:
    GIT_DEPTH: "0"

  script:
    - |
      Write-Host "Starting Cargo SonarQube analysis"

      if (-not $env:SONAR_HOST_URL -or
          -not $env:SONAR_TOKEN -or
          -not $env:SONAR_PROJECT_KEY) {
        throw "Required SonarQube variables are missing"
      }

      cargo --version
      cargo clippy --version

      $scanner = "C:\Tools\sonar-scanner\bin\sonar-scanner.bat"

      if (-not (Test-Path $scanner)) {
        throw "SonarScanner CLI not found"
      }

      & $scanner `
        "-Dsonar.projectKey=$env:SONAR_PROJECT_KEY" `
        "-Dsonar.sources=src" `
        "-Dsonar.qualitygate.wait=true"

      if ($LASTEXITCODE -ne 0) {
        throw "SonarQube analysis or Quality Gate failed"
      }

      Write-Host "SonarQube validation PASSED"

  allow_failure: false
~~~

The scanner reads SONAR_TOKEN and SONAR_HOST_URL from its process environment.

Avoid providing the token as a command-line argument.

The scanner command must execute from the project root containing Cargo.toml, or be configured with the appropriate project base directory.

### Expected result

| Condition | GitLab result |
|---|---|
| Scanner missing | Failed |
| Server unreachable | Failed |
| Invalid token | Failed |
| Analysis permission missing | Failed |
| Analysis completed, Quality Gate passed | Passed |
| Analysis completed, Quality Gate failed | Failed |

The `sonar.qualitygate.wait=true` property makes the scanner wait for the Quality Gate result before determining job success.

---

## 13. Common troubleshooting scenarios

| Symptom | Possible cause | Suggested solution |
|---|---|---|
| Scanner works locally, not in pipeline | Different Windows account or PATH | Use absolute path |
| Scanner missing | CLI not installed | Install ZIP distribution |
| Java execution failure | Java unavailable or incompatible | Verify scanner JRE requirements |
| Connection refused or timeout | Network/proxy/firewall | Test server URL from runner |
| SSL/PKIX failure | Enterprise TLS certificate trust | Configure appropriate truststore |
| HTTP 401 | Invalid or missing token | Verify GitLab variables |
| HTTP 403 | Insufficient permissions | Verify SonarQube authorization |
| Missing Cargo executable | Runner PATH differs | Check Cargo installation and runner account |
| Quality Gate fails | SonarQube rules violated | Inspect project analysis dashboard |

For enterprise environments, also consider Nexus/network restrictions, proxy configuration, internal certificates and security policies.

---

## 14. Verification checklist

### Local machine

- [ ] Windows GitLab Runner is installed and registered.
- [ ] Shell executor uses PowerShell.
- [ ] SonarScanner CLI executable exists.
- [ ] SonarScanner version command succeeds.
- [ ] Cargo is installed.
- [ ] Clippy is installed.

### GitLab pipeline

- [ ] Runner tag matches CI job configuration.
- [ ] Verification job executes on intended runner.
- [ ] Runner account can access scanner directory.
- [ ] SonarScanner version appears in pipeline logs.

### SonarQube integration

- [ ] SONAR_HOST_URL exists.
- [ ] SONAR_TOKEN exists and is valid.
- [ ] SONAR_PROJECT_KEY exists.
- [ ] SonarQube server is reachable from runner.
- [ ] Authentication validation succeeds.
- [ ] Actual analysis completes.
- [ ] Quality Gate result controls pipeline success.

---

## 15. Recommended implementation order

| Step | Task | Validation |
|---|---|---|
| 1 | Check existing scanner installation | `Get-Command` |
| 2 | Install scanner if missing | Absolute-path execution |
| 3 | Validate scanner locally | `sonar-scanner.bat -v` |
| 4 | Create temporary GitLab verification job | Job succeeds |
| 5 | Configure SonarQube project variables | Variables visible in GitLab settings |
| 6 | Validate server connectivity | Server version returned |
| 7 | Validate token authentication | `valid=true` |
| 8 | Validate Cargo and Clippy | Both commands execute |
| 9 | Add real Sonar analysis stage | Scanner uploads analysis |
| 10 | Validate Quality Gate | Gate failure causes job failure |

Do not introduce the actual Sonar analysis stage until the scanner execution and server connection have been independently verified.

---

## 16. References

- SonarScanner CLI:
  https://docs.sonarsource.com/sonarqube-server/analyzing-source-code/scanners/sonarscanner/

- SonarQube analysis parameters:
  https://docs.sonarsource.com/sonarqube-server/analyzing-source-code/analysis-parameters/

- GitLab Runner Shell executor:
  https://docs.gitlab.com/runner/executors/shell/

- GitLab CI/CD variables:
  https://docs.gitlab.com/ci/variables/

- Rust Clippy:
  https://doc.rust-lang.org/clippy/
