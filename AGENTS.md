# Codex operating instructions

- Read [ROADMAP.md](ROADMAP.md), [CURRENT-STATE.md](CURRENT-STATE.md), and the relevant phase. Work on one bounded documentation step at a time.
- Prioritize the ability to read, modify and troubleshoot existing enterprise configurations. Explain purpose, internal flow, realistic use, annotated examples, common failures, configuration-reading exercises with worked answers, and Java/Maven comparisons where useful.
- Put definitions, the execution model and relevant diagrams before exercises. Link the theory from the phase plan.
- Use Markdown for examples, including complete configuration files in fenced blocks where useful. Label examples and traces as illustrative. Verify syntax and behavioral claims against official documentation and identify assumptions about versions and editions.
- Keep exercises solvable offline through reading and reasoning. Use synthetic inputs and keep credentials and sensitive traces out of the repository.
- Defer implementation and runtime verification to [FUTURE-LABS.md](FUTURE-LABS.md). Live access checks, installations, runner registration, pipeline runs and vendor integrations require an explicit request for live work.
- After each step, update CURRENT-STATE.md with deliverables, documentation checks and the next step. Mark a phase DOCUMENTATION COMPLETE when its explanations, examples, troubleshooting and assessments are ready. Track implementation and runtime verification separately as DEFERRED.
