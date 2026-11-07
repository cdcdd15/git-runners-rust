# Readiness assessment

Use the [scenarios](../docs/enterprise-scenarios/README.md) and the questions in each [phase plan](../docs/roadmap/README.md).

- **Operator, 45 minutes.** Given a sanitized trace and graph, locate the failing boundary and give the smallest discriminating check, mitigation and recovery proof.
- **Builder, 75 minutes.** Propose a change to a supplied pipeline. Explain the YAML diff, predict the job graph for two relevant events and provide a rollback plan.
- **Gate interpretation, 30 minutes.** Classify passing, blocking and unavailable outcomes from quality, dependency policy and SAST fixtures. Tie each outcome to the source commit and report.

Score each exercise out of four, awarding one point each for a correct diagnosis or design, reasoning grounded in the supplied evidence, preservation of trust boundaries, and a clear handoff. Pass at 10/12 with the trust-boundary point on all three exercises. Use the supplied fixtures to score the offline assessment. Live sign-off belongs to the [future labs](../FUTURE-LABS.md).
