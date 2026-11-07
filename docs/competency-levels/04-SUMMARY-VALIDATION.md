# Summary and validation

The three levels measure a progression from explaining an existing configuration to proposing a controlled change and diagnosing a deviation. Use the Ledger Gateway scenario throughout so differences in performance come from the task and evidence. The assessments use illustrative, unexecuted fixtures. They measure readiness to reason from enterprise documentation and evidence, while supervised runtime experience belongs to a separate record. [Competency model](00-COMPETENCY-MODEL.md)

## Compare the three levels

| Level | Assessment input | Required output | Observable failure |
|---|---|---|---|
| [L1 · Understand](01-L1-UNDERSTAND.md) | Configuration and stated event | Annotated graph and explanation of component ownership | Attributes a scheduling or policy decision to the shell |
| [L2 · Modify](02-L2-MODIFY.md) | Baseline and business request | Proposed diff, event predictions, approval map and rollback | Changes behavior without identifying the affected paths |
| [L3 · Troubleshoot](03-L3-TROUBLESHOOT.md) | Symptoms, configuration and evidence | Ranked hypotheses, discriminating checks, correction and recovery proof | Picks a cause before comparing it with the trace |

Start with L1 because an incorrect baseline makes both the diff and the diagnosis unreliable. At L2, explain how a proposed change can affect a second event or trust boundary. At L3, treat that prediction as a hypothesis and compare it with observed evidence. Revisit the prior level when an assessment exposes a gap. For instance, if a learner cannot explain why the cache restored successfully while a report was missing, repeat the L1 distinction between cache reuse and a producer-specific artifact before scoring the incident again.

## Technology-by-competency matrix

| Area | L1 check | L2 check | L3 check | Primary |
|---|---|---|---|---|
| Rust and Cargo | Explain manifest, lockfile and workspace | Predict feature and dependency changes | Classify lockfile, compiler and linker failures | L2 |
| GitLab CI/CD | Identify event, rules and graph | Predict affected and unaffected jobs | Locate admission, assignment or runtime failure | **L3** |
| Variables and permissions | Determine eligible value and owner | Map credential and approval changes | Distinguish scope, precedence and authorization | **L3** |
| Cache and artifacts | Identify reusable and produced inputs | Review a key and transfer edge | Separate stale cache, disabled transfer and expiry | **L3** |
| Windows runners | Locate executor, shell and identity | Translate shell commands and tags | Separate eligibility, service PATH and toolchain faults | **L3** |
| Actions migration | Map events, steps and runners | Predict event and permission parity | Explain observed parity drift | L2 |
| SonarQube, Nexus IQ, Fortify | Identify each evidence type | Review inputs, credential scope and gate behavior | Separate missing input, service error and policy result | L2 |

## Practical assessment and scoring

Allocate 30 minutes for L1, 50 minutes for L2 and 45 minutes for L3. Use one exercise from the corresponding module and have the learner write an answer before reading its key. For each level, score the five checklist items below. Give zero for missing or materially wrong, one for a correct but incomplete answer, and two for a correct answer grounded in the supplied evidence. Pass at **8/10**, with two points on the item marked **required**. Otherwise, repeat that level with a changed input after reviewing the specific gap.

### L1 checklist

- [ ] Name the event, ref and configuration revision.
- [ ] Predict job selection, ordering and the relevant dependency.
- [ ] **Required** — Attribute pipeline decisions to GitLab and execution to the correct runner, executor and shell.
- [ ] Identify the source of a variable and of each required input.
- [ ] Explain which outcomes follow from the fixture and which depend on its assumptions.

### L2 checklist

- [ ] Describe the requirement as observable behavior and show a minimal diff.
- [ ] Predict results for the target event and one unaffected event.
- [ ] **Required** — Preserve credential and policy boundaries and name the relevant approval owners.
- [ ] Review shell, data paths, dependencies and regression risks.
- [ ] Specify offline review checks and a rollback for every affected surface.

### L3 checklist

- [ ] Identify the last successful boundary with a trace or configuration citation.
- [ ] Rank two plausible hypotheses and choose evidence that separates them.
- [ ] **Required** — Justify the root cause and a safe correction without weakening controls.
- [ ] Define recovery evidence tied to the original event and commit.
- [ ] Propose a preventive control and identify the responsible owner.

## Calibrate answers

| Level | Insufficient answer | Acceptable answer |
|---|---|---|
| L1 | “The Windows tag starts PowerShell.” | “The tag filters eligible runners. This runner's Shell configuration selects PowerShell Core.” |
| L2 | “Switch the tag and merge.” | “Change the tag and confirm the host contract. Keep the MR and protected-push graph, and review artifact paths and approval ownership.” |
| L3 | “The scanner is broken. Retry it.” | “The consumer failed before submission. The producer uploaded coverage and the dependency disables transfer. Restore the edge and confirm report provenance and gate status.” |

## Learning gaps and next activities

If a learner treats a pipeline and job as interchangeable, redraw the flow in [P0](../roadmap/P0.md) with an explicit queue boundary. If a change preserves its happy path but alters a scheduled run, work through the event matrix in [P3](../roadmap/P3.md). If a diagnosis relies on a successful interactive command, compare the runner service identity and its environment in [P6](../roadmap/P6.md). For a gate interpretation gap, practice separating producer output, submission, processing and policy enforcement in [P8–P10](../roadmap/README.md).

## Final readiness checklist

- [ ] I can explain an inherited pipeline from event to verdict and identify its external settings.
- [ ] I can review a change, predict regressions and give an approval and rollback plan.
- [ ] I can rank incident hypotheses and justify a scoped correction using evidence.
- [ ] I can separate a quality decision, dependency policy and source security finding from infrastructure failure.
- [ ] I passed each level's threshold and recorded version assumptions and gaps for a handoff.

Passing establishes readiness for documentation-based review and incident reasoning. Production experience requires separate evidence from authorized execution, change review and recovery under real operating constraints. Track that work in [Future labs](../../FUTURE-LABS.md).
