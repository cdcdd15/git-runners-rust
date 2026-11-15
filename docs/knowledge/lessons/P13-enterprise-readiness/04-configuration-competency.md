# Configuration competency

## Safe change is more than valid syntax
A YAML file can parse while expressing the wrong behavior. Configuration competence includes knowing the owning system, the effect of a change, the scope of its permissions, and the evidence needed to validate it. For Windows Rust pipelines, configuration is spread across GitLab YAML, runner TOML, Windows host settings, Cargo configuration and scanner administration.

## Ownership matrix
| Configuration | Owner | Typical risk |
|---|---|---|
| `.gitlab-ci.yml` | Project maintainers | Unexpected job graph or secret exposure |
| `config.toml` | Runner administrators | Host access and concurrency |
| Windows service account / PATH | Platform administrators | Privilege or toolchain drift |
| `Cargo.toml` / `Cargo.lock` | Rust maintainers | Dependency and feature changes |
| SonarQube profiles and gates | Quality governance | Unreviewed policy weakening |
| Nexus IQ policy | Security / compliance | License and vulnerability acceptance |
| Fortify integration | Security tooling | Unsupported analysis or false assurance |

## Annotated example
```yaml
stages: [test, package]

rust_test:
  stage: test
  tags: [windows, rust]
  script:
    - cargo test --locked

package:
  stage: package
  tags: [windows, rust]
  needs:
    - job: rust_test
  script:
    - cargo build --locked --release
  artifacts:
    paths:
      - target/release/example.exe
    expire_in: 7 days
```

This is a learning example, not a verified production pipeline. The executable name must match the actual crate; `tags` do not install tools; `needs` controls job ordering, and a passing test job does not automatically satisfy external security gates. The test job has no artifacts, so the package job recompiles; that may be intentional, but should be recognized.

## Change review sequence
State the desired behavior and current behavior. Identify the owner and permission needed. Predict changes to job inclusion, dependencies, variable exposure and outputs. Make the smallest coherent edit. Validate YAML structure and conceptual graph. In a future authorized environment, use CI lint, a test branch and sanitized job traces to verify actual behavior.

## Negative test
A developer proposes `allow_failure: true` for a required security job to “unblock CI.” This changes release policy, not merely reliability. Reject it without explicit risk acceptance and an alternative controlled process.

**Outcome:** Explain the intended effect, side effects and validation plan for each proposed change.
