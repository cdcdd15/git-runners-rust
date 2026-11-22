# SonarQube in a Windows Rust GitLab Pipeline — Maven vs Cargo

> Scope: Windows GitLab Runner with PowerShell shell executor. This study consolidates only the concepts, diagrams, comparison tables, and command examples discussed on 22 November 2026; it is not copied from earlier generated files.

**Shared foundations:** See [Common Maven vs Rust baseline & reusable repository organization](00-common-maven-vs-rust-and-repository-organization.md) for the build-tool comparison, Windows runner process diagram, shared `ci/scripts/` directory structure, and PowerShell syntax.

## 1. Purpose and the CycloneDX analogy

SonarQube focuses on code quality and static analysis. In the previous discussion, **Clippy** was the closest *Rust-specific conceptual analogue* to `cargo-cyclonedx`, but these tools do **not** do the same work: `cargo-cyclonedx` generates a dependency inventory (SBOM); Clippy performs Rust lint/static checks. For supported SonarQube editions/versions, its Rust analyzer can use Clippy automatically, so a separate report-generation step may be unnecessary.

| Question | Maven / Java | Rust / Cargo |
|---|---|---|
| What triggers SonarQube? | Maven scanner plugin such as `mvn sonar:sonar` | Standalone SonarScanner CLI, often `sonar-scanner.bat` on Windows |
| What prepares code findings? | Java compiler/project context plus Sonar analyzers | Rust analyzer; optionally Clippy findings |
| Is Clippy the same as CycloneDX? | N/A | No—Clippy analyzes code; CycloneDX describes dependencies |
| Where is the analysis/reporting service? | Remote SonarQube Server | Remote SonarQube Server |
| What runs on Windows? | `mvn.cmd` and Maven plugin | `cargo.exe`, potentially Clippy, and SonarScanner CLI |

```mermaid
flowchart LR
  A[Rust source] --> B[Clippy / Rust analyzer]
  B --> C[SonarScanner CLI]
  C --> D[(Remote SonarQube Server)]
```

This is a **conceptual** flow: depending on server/scanner version, SonarScanner can invoke Clippy rather than reading a separately generated Clippy report. Unlike Nexus IQ's SBOM flow, a universal intermediary file is not required.

## 2. Local vs remote boundaries

| Location | Component | Function |
|---|---|---|
| Git repository | `.gitlab-ci.yml`, `ci/scripts/sonar.ps1`, optional `sonar-project.properties` | Job orchestration and project configuration |
| Windows runner | PowerShell, Rust toolchain, SonarScanner CLI (`sonar-scanner.bat`) | Launch local scanner, read source and contact server |
| Windows runner (possible) | Clippy / `cargo clippy` | Rust lint analysis; automatic or separately invoked depending on setup |
| Remote | SonarQube Server | Analysis results, issues and quality gates |

## 3. Maven commands versus Rust commands

**Java / Maven scanner plugin:**

```powershell
mvn clean verify
mvn sonar:sonar
```

**Rust scanner launcher on Windows:**

```powershell
& "C:\Tools\sonar-scanner\bin\sonar-scanner.bat" `
  "-Dsonar.projectKey=rust-demo" `
  "-Dsonar.sources=src" `
  "-Dsonar.host.url=$env:SONAR_HOST_URL" `
  "-Dsonar.token=$env:SONAR_TOKEN"
```

Here, `sonar-scanner.bat` is a Windows **launcher**, not a Maven goal or Cargo extension. The `&` operator is necessary to invoke an executable whose path is stored in a string. `mvn sonar:sonar` executes the SonarScanner for Maven plugin, whereas Rust commonly uses a standalone CLI.

## 4. Separate `ci/scripts/sonar.ps1`

```powershell
$ErrorActionPreference = "Stop"

$scanner = "C:\Tools\sonar-scanner\bin\sonar-scanner.bat"
if (-not (Test-Path $scanner)) { throw "SonarScanner missing: $scanner" }
if (-not $env:SONAR_HOST_URL -or -not $env:SONAR_TOKEN) {
  throw "Missing SONAR_HOST_URL or SONAR_TOKEN GitLab variable"
}

& $scanner `
  "-Dsonar.projectKey=rust-demo" `
  "-Dsonar.sources=src" `
  "-Dsonar.host.url=$env:SONAR_HOST_URL" `
  "-Dsonar.token=$env:SONAR_TOKEN"
if ($LASTEXITCODE -ne 0) { throw "SonarScanner failed: $LASTEXITCODE" }
```

If your SonarQube instance supports Rust/Clippy integration, avoid adding an extra Clippy import mechanism until its behavior is confirmed. Where strict gating is wanted, configure the scanner/CI integration to wait for and enforce the **quality gate**, not merely to submit an analysis. The example above is a baseline submission job.

## 5. Minimal `.gitlab-ci.yml` snippet

```yaml
stages:
  - build
  - test
  - security

sonar_scan:
  stage: security
  tags:
    - windows
    - rust
  script:
    - '& .\ci\scripts\sonar.ps1'
```

For the same pipeline, a Rust build and test script would use `cargo build --locked` and `cargo test --locked`, checking `$LASTEXITCODE`. In Java, `mvn package` and `mvn test` occupy comparable jobs. Keep the tool-specific command in `.ps1` and the stage/tag configuration in YAML.

## 6. Three integration layers in context

| Layer | SonarQube | Nexus IQ | Fortify |
|---|---|---|---|
| 1. Language-aware preparation | Rust analyzer / Clippy | `cargo-cyclonedx` SBOM | Source packaging, Rust analysis mode must be supported |
| 2. CI integration | SonarScanner CLI | Nexus IQ CLI | `fcli` / ScanCentral Client |
| 3. Remote platform | SonarQube Server | Nexus IQ Server | Fortify SSC / ScanCentral |

**Takeaway:** Clippy is an analyzer, not a standardized SBOM format. SonarScanner is a vendor scanner, and `sonar-scanner.bat` is simply its Windows entry point. The Maven equivalent often appears as a Maven plugin goal; Rust usually makes the scanner boundary explicit.
