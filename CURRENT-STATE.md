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

## P2.1 · Completed

- Added the [Cargo manifests and lockfile exercise](docs/labs/p2-1-read-cargo-manifests-and-lockfile.md) with a two-member workspace, feature graph walkthrough, mirror configuration and five worked review questions.
- Checked version requirements, lockfile resolution, feature selection and source replacement against the Cargo Book and the pinned Serde manifest. Verified local links, TOML snippet syntax, fixture relationships and whitespace. Cargo commands and fixtures are illustrative and unexecuted.

## P2.2 · Completed

- Added the [Cargo build and packaging review](docs/labs/p2-2-review-cargo-build-and-packaging.md) with an output matrix, Windows artifact handoff, packaging review and four worked questions.
- Checked profile, target layout, package behavior and locked resolution against Cargo documentation. Verified local links, example structure, fixture paths and whitespace. The commands and traces are illustrative and unexecuted.

## P3.1 · Completed

- Added the [GitLab CI reading exercise](docs/labs/p3-1-read-a-complete-gitlab-ci-file.md) with three complete illustrative configurations, a core keyword review card and five worked questions.
- Compared YAML, inheritance, runner capabilities and CI Lint behavior with official GitLab documentation. Verified Markdown links, YAML syntax and expected example structure locally. GitLab CI Lint and pipeline execution remain deferred.

## P3.2 · Completed

- Added the [reusable pipeline graph exercise](docs/labs/p3-2-review-a-reusable-pipeline-graph.md) with a typed include, a seven-case event matrix, keyword review card and four worked answers.
- Checked the configuration and expected graphs against official GitLab documentation. Verified YAML syntax, the example's include and graph references, and Markdown links locally. GitLab CI Lint and pipeline execution remain deferred.

## Phase status

| Phase | Documentation | Implementation | Runtime verification |
|---|---|---|---|
| P0 | DOCUMENTATION COMPLETE | DEFERRED | DEFERRED |
| P1 | DOCUMENTATION COMPLETE | DEFERRED | DEFERRED |
| P2 | DOCUMENTATION COMPLETE | DEFERRED | DEFERRED |
| P3 | DOCUMENTATION COMPLETE | DEFERRED | DEFERRED |
| P4–P13 | PLANNED | DEFERRED | DEFERRED |

Next step is [P4.1](docs/roadmap/P4.md), an offline review of GitLab variable permissions and precedence.
