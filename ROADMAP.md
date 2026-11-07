# Knowledge-first roadmap

## Learning tracks

- **Track A · Enterprise survival.** Follow P0 → P3 → P4 → P6, then P5 once Cargo basics are in place. Read the P8–P10 support and result contracts alongside an existing P11 pipeline. Finish with P12 triage and the P13 operator exercise. Use P1.1 and P2.1 when a Cargo or compiler diagnosis requires them.
- **Track B · Read and design from scratch.** P0 → P1 → P2 → P3 → P4 → P5 → P6 → P7 → P8/P9/P10 → P11 → P12 → P13. P7 and the three scanner phases can be scheduled independently after their prerequisites.

## Phase dependencies and study effort

The hour ranges are provisional study estimates. All current phases use offline reading, configuration review and tabletop exercises. The separate [future labs](FUTURE-LABS.md) track deferred implementation and runtime verification.

| Phase | Prerequisites | Hours | Exercise mode |
|---|---|---:|---|
| [P0 · GitLab execution lifecycle](docs/roadmap/P0.md) | — | 2–3 | Offline |
| [P1 · Rust for Java developers](docs/roadmap/P1.md) | P0 | 5–7 | Offline |
| [P2 · Cargo builds and dependency management](docs/roadmap/P2.md) | P1 | 4–6 | Offline |
| [P3 · GitLab CI YAML from zero](docs/roadmap/P3.md) | P0 | 5–8 | Offline |
| [P4 · Variables, roles and secret boundaries](docs/roadmap/P4.md) | P3 | 3–5 | Offline |
| [P5 · Cache, artifacts and reuse](docs/roadmap/P5.md) | P2, P3 | 4–6 | Offline |
| [P6 · Windows Shell runner](docs/roadmap/P6.md) | P3, P4 | 6–9 | Offline |
| [P7 · GitHub Actions migration](docs/roadmap/P7.md) | P5, P6 | 4–6 | Offline |
| [P8 · SonarQube quality and coverage](docs/roadmap/P8.md) | P2, P5, P6 | 4–6 | Offline |
| [P9 · Nexus IQ dependency policy](docs/roadmap/P9.md) | P2, P5, P6 | 3–5 | Offline |
| [P10 · Fortify static security analysis](docs/roadmap/P10.md) | P2, P5, P6 | 4–7 | Offline |
| [P11 · End-to-end enterprise pipeline](docs/roadmap/P11.md) | P4, P5, P6, P8, P9, P10 | 6–10 | Offline |
| [P12 · Enterprise troubleshooting](docs/roadmap/P12.md) | P4, P5, P6; P11 for integrated drills | 4–6 | Offline |
| [P13 · Enterprise readiness assessment](docs/roadmap/P13.md) | P7, P11, P12 | 3–5 | Offline |

## Minimum viable enterprise readiness

For work on an existing pipeline, first be able to trace a job, review a YAML change, explain a variable's scope, distinguish a stale cache from a missing artifact, and diagnose Cargo lookup under the Windows service identity. Then interpret the three gate outcomes from an existing trace and diagnose one incident. Use P0.1, P1.1, P2.1, P3.2, P4.2, P5.1–2, P6.2, read-only portions of P8–P11, P12.1 and the P13.1 operator exercise. Use illustrative or sanitized configurations, job graphs and traces as inputs.

## Completion criteria

Mark a phase DOCUMENTATION COMPLETE when its conceptual explanations, annotated configuration, troubleshooting guide and reading assessment are ready. Check examples and version-sensitive claims against official references. Record implementation and runtime verification separately as DEFERRED. [Progress log](CURRENT-STATE.md).
