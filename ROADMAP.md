# Implementation roadmap

## Learning tracks

- **Track A · Enterprise survival.** Follow P0 → P3 → P4 → P6, then P5 once Cargo basics are in place. Read the P8–P10 support and result contracts alongside an existing P11 pipeline. Finish with P12 triage and the P13 operator exercise. Use P1.1 and P2.1 when a Cargo or compiler diagnosis requires them.
- **Track B · Build from scratch.** P0 → P1 → P2 → P3 → P4 → P5 → P6 → P7 → P8/P9/P10 → P11 → P12 → P13. P7 and the three scanner phases can be scheduled independently after their prerequisites. Book vendor access and the Windows VM early.

## Phase dependencies and effort

Estimates cover study, sandbox implementation and verification, excluding access and procurement wait time. A full pass is approximately **57–89 hours**.

| Phase | Prerequisites | Hours | Lab access |
|---|---|---:|---|
| [P0 · GitLab execution lifecycle](docs/roadmap/P0.md) | — | 2–3 | Local + GitLab |
| [P1 · Rust for Java developers](docs/roadmap/P1.md) | P0 | 5–7 | Local |
| [P2 · Cargo builds and dependency management](docs/roadmap/P2.md) | P1 | 4–6 | Local |
| [P3 · GitLab CI YAML from zero](docs/roadmap/P3.md) | P0 | 5–8 | GitLab |
| [P4 · Variables, roles and secret boundaries](docs/roadmap/P4.md) | P3 | 3–5 | GitLab |
| [P5 · Cache, artifacts and reuse](docs/roadmap/P5.md) | P2, P3 | 4–6 | GitLab |
| [P6 · Windows Shell runner](docs/roadmap/P6.md) | P3, P4 | 6–9 | GitLab + Windows |
| [P7 · GitHub Actions migration](docs/roadmap/P7.md) | P5, P6 | 4–6 | GitLab + Windows |
| [P8 · SonarQube quality and coverage](docs/roadmap/P8.md) | P2, P5, P6 | 4–6 | Local + GitLab + Vendor for licensed features |
| [P9 · Nexus IQ dependency policy](docs/roadmap/P9.md) | P2, P5, P6 | 3–5 | Local simulation + GitLab + licensed Vendor |
| [P10 · Fortify static security analysis](docs/roadmap/P10.md) | P2, P5, P6 | 4–7 | Local simulation + GitLab + licensed Vendor |
| [P11 · End-to-end enterprise pipeline](docs/roadmap/P11.md) | P4, P5, P6, P8, P9, P10 | 6–10 | GitLab + Windows + licensed Vendor for live validation |
| [P12 · Enterprise troubleshooting](docs/roadmap/P12.md) | P4, P5, P6; P11 for integrated drills | 4–6 | Local + GitLab + Windows; Vendor optional |
| [P13 · Enterprise readiness assessment](docs/roadmap/P13.md) | P7, P11, P12 | 3–5 | Local + GitLab + Windows; Vendor for live sign-off |

## Minimum viable enterprise readiness

For work on an existing pipeline, first be able to trace a job, lint a YAML change, explain a variable's scope, distinguish a stale cache from a missing artifact, and verify Cargo under the Windows service identity. Then interpret the three gate outcomes from an existing trace and diagnose one incident. Use P0.1, P1.1, P2.1, P3.2, P4.2, P5.1–2, P6.2, read-only portions of P8–P11, P12.1 and the P13.1 operator exercise. Use an existing sandbox and supplied traces where available. For permission or access gaps, keep the result as a tabletop exercise.

## Review checkpoint

Confirm tracks and scope, available GitLab instance and sandbox roles, Windows VM and service identity, and vendor versions/entitlements before starting build steps. See [prerequisites](README.md) and [state](CURRENT-STATE.md).
