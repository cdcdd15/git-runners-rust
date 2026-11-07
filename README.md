# rust-gitlab-runners

A Markdown-first training project for Java, Spring and Maven developers joining an enterprise Rust team. Learn to trace, modify and troubleshoot GitLab pipelines running Cargo and enterprise scanners on Windows.

Start with the [roadmap](ROADMAP.md) and [progress log](CURRENT-STATE.md).

| Section | What to use it for |
|---|---|
| [Architecture](docs/architecture/README.md) | Trace a job from push to cleanup |
| [Concepts](docs/concepts/README.md) | Look up configuration, trust boundaries and vendor support |
| [Phase plans](docs/roadmap/README.md) | Pick the next bounded step |
| [Labs](docs/labs/README.md) | Find exercises by environment |
| [Cheat sheets](docs/cheat-sheets/README.md) | Look up operational checks |
| [Troubleshooting](docs/troubleshooting/README.md) | Separate scheduling, execution and policy failures |
| [Enterprise scenarios](docs/enterprise-scenarios/README.md) | Practice decisions from realistic incident reports |
| [Examples](examples/README.md) | Find the planned Rust, CI, migration and runner examples |
| [Assessments](assessments/README.md) | Measure operator and builder readiness |

Local exercises will need Git, a text editor, rustup, a pinned Rust toolchain with rustfmt and Clippy, and access to an approved Cargo registry or mirror. Windows labs need a disposable VM, administrative access for setup, PowerShell 7, Git for Windows and Visual Studio Build Tools with the C++ workload and Windows SDK for the MSVC Rust target. Give the service identity access to the installed tools and its build/cache directories.

GitLab labs need a sandbox project, a compatible Runner and access to pipeline logs and CI Lint. Coordinate project/group administration and host administration separately. Vendor labs also need test applications, approved identities and connectivity to supported SonarQube, Sonatype Lifecycle and OpenText environments. Record actual versions, entitlements and network requirements before selecting a live integration.
