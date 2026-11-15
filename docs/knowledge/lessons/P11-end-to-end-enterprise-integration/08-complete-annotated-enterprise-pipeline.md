# Annotated enterprise pipeline: architecture-first reference

## Read this before copying YAML

This is a **documentation-only reference**, not a production-ready pipeline. Cargo commands are concrete examples; SonarQube, Nexus IQ and Fortify integrations require approved organization-specific tooling, versions, endpoints, formats and credentials. The reference deliberately **fails closed** when an adapter is not configured, rather than presenting a `Write-Host` placeholder as a passing security scan.

## Reference `.gitlab-ci.yml`

```yaml
stages:
  - validate
  - test
  - build
  - analyze
  - gate
  - release

workflow:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
    - if: '$CI_COMMIT_TAG'

variables:
  CARGO_HOME: "$CI_PROJECT_DIR/.cargo"

.cargo_cache:
  cache:
    key:
      prefix: "win-rust-stable"
      files: [Cargo.lock]
    paths:
      - .cargo/registry/
      - .cargo/git/
    policy: pull

validate:
  stage: validate
  tags: [windows, rust]
  extends: .cargo_cache
  script:
    - 'cargo fmt --all -- --check'
    - 'if ($LASTEXITCODE -ne 0) { throw "fmt failed" }'
    - 'cargo clippy --workspace --all-targets -- -D warnings'
    - 'if ($LASTEXITCODE -ne 0) { throw "clippy failed" }'

test:
  stage: test
  tags: [windows, rust]
  extends: .cargo_cache
  needs: [validate]
  script:
    - 'cargo test --workspace --locked'
    - 'if ($LASTEXITCODE -ne 0) { throw "tests failed" }'

build:
  stage: build
  tags: [windows, rust]
  extends: .cargo_cache
  needs: [validate]
  script:
    - 'cargo build --release --locked'
    - 'if ($LASTEXITCODE -ne 0) { throw "build failed" }'
  artifacts:
    paths:
      - target/release/example.exe
    expire_in: 7 days

# The following adapters are intentionally fail-closed.
# Replace each script with a validated, approved integration.
sonarqube:
  stage: analyze
  tags: [windows, sonar]
  needs: [test]
  script:
    - 'throw "CONFIGURATION REQUIRED: SonarQube scan and final gate check"'

nexus_iq:
  stage: analyze
  tags: [windows, nexus-iq]
  needs: [validate]
  script:
    - 'throw "CONFIGURATION REQUIRED: supported Cargo inventory and IQ policy evaluation"'

fortify:
  stage: analyze
  tags: [windows, fortify]
  needs: [validate]
  script:
    - 'throw "CONFIGURATION REQUIRED: verify Rust support and approved Fortify integration"'

release_gate:
  stage: gate
  tags: [windows, powershell]
  needs:
    - {job: build, artifacts: true}
    - {job: sonarqube, artifacts: false}
    - {job: nexus_iq, artifacts: false}
    - {job: fortify, artifacts: false}
  script:
    - 'Write-Host "Required upstream jobs completed successfully"'
    - 'if (-not (Test-Path "target/release/example.exe")) { throw "Binary missing" }'

release:
  stage: release
  tags: [windows, protected-release]
  needs:
    - {job: release_gate, artifacts: false}
    - {job: build, artifacts: true}
  rules:
    - if: '$CI_COMMIT_TAG'
      when: manual
    - when: never
  script:
    - 'throw "CONFIGURATION REQUIRED: approved signing and publishing workflow"'
```

## How to interpret the example

**Validate** checks formatting and Clippy. **Test** and **build** run after validation and can execute independently. The analysis jobs represent three mandatory gates, each failing until a real integration is configured. The release gate requires successful completion of those jobs and the build artifact. The release job is restricted by tags and tag-pipeline rules, but a real deployment must also use protected tags, a protected runner, approved secrets and release approvals.

The YAML does not generate coverage, an SBOM or Fortify inputs. Those require explicit producer jobs if the chosen integrations need them. Likewise, a SonarQube adapter must wait for the **final** quality gate, Nexus IQ must evaluate the correct application/stage, and Fortify must return a supported authoritative policy result. Only then can the downstream job status represent genuine evidence.

## Important limitations

The example uses a placeholder executable name, does not pin the Rust toolchain or scanner versions, and does not implement token rotation, artifact signing or exception governance. It assumes `pwsh` on each Windows Shell runner and that `cargo fmt` and Clippy are installed. `needs: [validate]` means no upstream artifacts are downloaded from that job. Do not treat these omissions as implied production defaults.

## Extension design

For a production version, add a coverage producer with a verified SonarQube importer, a Cargo dependency inventory producer compatible with Nexus IQ, an approved Fortify analysis path, immutable toolchain provisioning, a machine-readable evidence summary, and a protected release workflow. Test each adapter against the actual enterprise service before enabling the final release gate.

**Outcome:** This file provides a readable end-to-end skeleton while making unimplemented security controls impossible to mistake for successful scans.
