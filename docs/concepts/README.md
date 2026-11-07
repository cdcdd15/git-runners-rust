# Concepts and version checks

| Area | Model to use | Official reference |
|---|---|---|
| Rust | Ownership governs when values are dropped. Borrowing limits how a value can be accessed. `Result` makes failure part of a function signature. | [Rust Book](https://doc.rust-lang.org/book/) |
| Cargo | The manifest declares dependencies, features and targets. The lockfile records the resolved graph. A workspace shares resolution and a target directory. | [Cargo Book](https://doc.rust-lang.org/cargo/) |
| GitLab | Workflow rules select pipeline creation, job rules select graph membership, and shell commands run after scheduling. Check merged YAML before investigating the host. | [YAML reference](https://docs.gitlab.com/ci/yaml/), [CI Lint](https://docs.gitlab.com/ci/yaml/lint/) |
| SonarQube | Code quality and coverage gate. Rust support and PR/MR analysis depend on the server release and edition. Verify analyzer prerequisites, LCOV import and gate behavior separately. | [Rust analyzer](https://docs.sonarsource.com/sonarqube-server/analyzing-source-code/languages/rust), [coverage parameters](https://docs.sonarsource.com/sonarqube-server/analyzing-source-code/test-coverage/test-coverage-parameters) |
| Nexus IQ | Sonatype Lifecycle evaluates dependency policy. Its Rust documentation describes coordinate-based matching from Cargo.lock. Confirm installed support, scan scope and policy/license data before enforcing a gate. Nexus Repository hosts or proxies packages. | [Rust application analysis](https://help.sonatype.com/en/rust-application-analysis.html), [IQ CLI](https://help.sonatype.com/en/sonatype-iq-cli.html) |
| Fortify | OpenText SAST 26.1 documents Rust through AI-powered SAST. Without that mode, the guide describes regular-expression analysis. Confirm approved deployment, data handling, supported mode and evidence of Rust analysis before treating a result as a gate. | [OpenText SAST 26.1 guide, section 1.18](https://cabs.microfocus.com/documentation/fortify-static-code-analyzer-and-tools/2610/sast-ugd-26.1.0.pdf) |

The target GitLab edition and release, Runner release, Windows image, registry and scanner products are still unknown. At phase entry record the actual server and client versions, available permissions, supported integrations, and any differences from the public references.
