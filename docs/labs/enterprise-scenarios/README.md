# Enterprise scenarios

1. **Works on the administrator's desktop.** An MR job reports Cargo is missing after the runner service account changes. Determine the identity and executable path in the failing job, repair the environment and rerun on the same runner.
2. **Fast build, wrong artifact.** A Windows job succeeds after restoring a static cache key. A package consumer finds a different commit marker. Isolate cache reuse from artifact transfer and prove provenance after the repair.
3. **Green upload, blocked release.** A scanner accepts a submission but the release is blocked. Determine whether coverage, a policy decision or a transport timeout owns the outcome. Preserve the gate and supply a report or task ID.
4. **Fork demands privileged variables.** An MR job from an untrusted ref is missing credentials. Review the graph and runner eligibility, run unprivileged checks, and prove privileged scans remain confined to approved contexts.
