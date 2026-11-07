# Readiness assessment

Use the [scenarios](../docs/enterprise-scenarios/README.md) and the questions in each [phase plan](../docs/roadmap/README.md).

- **Operator, 45 minutes.** Given a sanitized trace and graph, locate the failing boundary and give the smallest discriminating check, mitigation and recovery proof.
- **Builder, 75 minutes.** Change an existing sandbox pipeline. Supply lint output, run evidence for two relevant events, and a rollback plan.
- **Gate interpretation, 30 minutes.** Classify passing, blocking and unavailable outcomes from quality, dependency policy and SAST fixtures. Tie each outcome to the source commit and report.

Score each exercise out of four, awarding one point each for a correct diagnosis or design, reproducible verification, preservation of trust boundaries, and a clear handoff. Pass at 10/12 with the trust-boundary point on all three exercises. Record live evidence and simulated evidence separately. Live sign-off requires the actual Windows runner and approved vendor environments.
