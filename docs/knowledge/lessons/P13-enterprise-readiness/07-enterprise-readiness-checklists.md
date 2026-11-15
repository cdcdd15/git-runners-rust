# Enterprise readiness checklists

## How to use these checklists
This is a documentation-based readiness review, not a certification. Mark each item **Verified**, **Partial**, **Unknown**, or **N/A**, and attach a short evidence reference. “Read the chapter” is not evidence that a candidate can apply the concept. For live operations, a separate authorized environment and change process are required.

## Architecture
- [ ] Explain GitLab coordinator, runner agent, executor and Windows service account roles.
- [ ] Draw the job lifecycle including cache, artifact retrieval and upload.
- [ ] Distinguish source-code analysis, dependency analysis and security analysis.
- [ ] Describe the release decision when a required scanner is unavailable.

## Rust and Cargo
- [ ] Explain crate, package, workspace and lockfile relationships.
- [ ] Identify target triple, profile and feature compatibility concerns.
- [ ] Explain why a cache miss must not change build correctness.
- [ ] Locate the correct executable output for a given Cargo project.

## GitLab and Windows
- [ ] Distinguish `workflow:rules` from job-level `rules`.
- [ ] Explain tags, runner scope, protection and capacity.
- [ ] Review a PowerShell script's native exit-code handling.
- [ ] Identify the service identity and its implications for PATH and ACLs.
- [ ] Separate `config.toml` settings from project YAML.

## Data and security
- [ ] Select cache versus artifact versus package registry appropriately.
- [ ] Explain protected and masked variables without overstating secrecy.
- [ ] Identify a cross-job handoff through `needs:artifacts`.
- [ ] Reject credential leakage through logs, artifacts or cache.

## Quality and compliance
- [ ] Explain SonarQube profiles, gates and coverage import.
- [ ] Explain Nexus IQ component identification and policy evaluation.
- [ ] State Fortify Rust support as a version-specific validation requirement.
- [ ] Explain why a successful scan upload is not automatically an accepted release.

## Troubleshooting
- [ ] Isolate a pending job before inspecting build commands.
- [ ] Diagnose an interactive-versus-service PATH mismatch.
- [ ] Investigate an artifact upload with no matching files.
- [ ] Differentiate TLS trust errors across Git, Cargo and scanners.
- [ ] Propose a verification step that could disprove the leading hypothesis.

## Readiness decision record
| Field | Record |
|---|---|
| Role and responsibility | Developer / maintainer / platform / security |
| Assessed scope | P0–P13 capabilities applicable to role |
| Evidence quality | Concept review, configuration review, or operational test |
| Unresolved critical gaps | Explicitly named |
| Next action | Focused learning or authorized validation |

**Rule:** Do not average away a critical unknown, such as whether a required scanner actually supports the project's Rust analysis path. Report it explicitly.

**Outcome:** A concise, auditable view of readiness and its limits.
