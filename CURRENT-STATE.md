# Current state

## Documentation baseline

- Created the project navigation, two learning tracks, dependency and effort table, P0–P13 plans with 28 bounded steps, architecture diagrams, lab catalog, support references, example indexes and assessment rubric.
- Checked GitLab YAML, variables, runner permissions and Windows execution behavior against GitLab documentation. Checked Rust integration claims against SonarSource, Sonatype and OpenText references.
- Verified locally that relative Markdown links resolve, all phase files and bounded step headings exist, Mermaid fences balance, phase estimates sum to 57–89 hours, and the scaffold contains Markdown files only.

## P0.1 · Completed

- Added and annotated a [simulated Windows Shell job trace](docs/labs/p0-1-job-trace.md). The lab includes pending, checkout-failure and cache-miss variants.
- Compared the annotation with the project sequence diagram and the [official GitLab job execution flow](https://docs.gitlab.com/ci/jobs/job_execution/). The simulated trace follows checkout → cache restore → artifact download → script → finalization → cache and artifact upload → cleanup → final status.
- Local verification passed. A Python check verified the 12 trace lines, their execution order and both navigation links. `git diff --check` passed. This step used a synthetic fixture on the local workspace.

## P0.2 · Completed

- Added the [offline pipeline walkthrough](docs/labs/p0-2-pipeline-walkthrough.md) with complete illustrative YAML, a simulated job graph and trace, and four worked configuration-reading exercises.
- Compared pipeline graph and log navigation, keyword behavior and runner eligibility with official GitLab documentation. Checked relative links, future-lab coverage, YAML parsing and whitespace locally.
- Updated the governance, phase plans, navigation and assessment rubric to use offline documentation. [Future labs](FUTURE-LABS.md) track runtime practice independently.

## Enterprise competency module

- Added the [L1–L3 competency model](docs/competency-levels/00-COMPETENCY-MODEL.md), three sets of worked exercises and a scored readiness assessment.
- Checked word counts excluding fenced examples, local cross-references, required exercise sections and scoring criteria. All examples and incidents are illustrative. The module is separate from phase implementation.

## P1.1 · Completed

- Added the [Rust library and CLI reading exercise](docs/labs/p1-1-read-a-rust-library-and-cli.md) with annotated excerpts, a Java comparison, an ownership and error-flow diagram, and five worked questions.
- Compared borrowing, lifetime, error propagation and file-read behavior with the official Rust references. Walked through the example inputs against the snippets and checked local links, fenced blocks and whitespace. The snippets remain illustrative and unexecuted.

## P1.2 · Completed

- Added an [offline review of a failing Rust change](docs/labs/p1-2-review-a-failing-rust-change.md) with two ownership diagnostics, a minimal borrowing repair, and a worked CLI regression matrix.
- Compared the diagnostics and test guidance with official Rust references. Checked Markdown links, fenced blocks, expected byte counts and whitespace locally. Rust examples and test results are illustrative and unexecuted.

## Phase status

| Phase | Documentation | Implementation | Runtime verification |
|---|---|---|---|
| P0 | DOCUMENTATION COMPLETE | DEFERRED | DEFERRED |
| P1 | DOCUMENTATION COMPLETE | DEFERRED | DEFERRED |
| P2–P13 | PLANNED | DEFERRED | DEFERRED |

Next step is [P2.1](docs/roadmap/P2.md), an offline review of Cargo manifests and a lockfile.
