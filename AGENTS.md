# Codex operating instructions

- Read [ROADMAP.md](ROADMAP.md), [CURRENT-STATE.md](CURRENT-STATE.md), and the relevant phase before editing.
- Wait for roadmap review before implementing Rust code, CI YAML, runner configuration or scanner automation. After review, execute one bounded step at a time and confirm its prerequisites from the state log.
- Use a disposable GitLab project and a dedicated Windows lab VM. Label every exercise Local, GitLab, Windows or Vendor as applicable. Use synthetic data and keep tokens, actual runner configuration and sensitive reports out of the repository.
- Verify version-sensitive behavior against official documentation for the installed versions. Record product edition, CLI version and the evidence for any scanner claim. Keep simulations visibly labeled.
- After each step, update CURRENT-STATE.md with commands, observed results, environment, open issues and the next step. Distinguish a proposed check from an executed one.
