# Concept-driven, knowledge-first roadmap

## Educational objectives

Reach enterprise readiness quickly through structured knowledge transfer. Learn to read existing Rust and Cargo projects, interpret GitLab CI/CD configuration, trace Windows runner execution and identify where settings and permissions are managed. Use that model to propose safe configuration changes and diagnose pipeline, runner and scanner failures. The project uses offline reading, configuration review and tabletop exercises. Infrastructure setup and application implementation belong to separately authorized [future labs](FUTURE-LABS.md).

## How scope is determined

Start each phase by mapping the technical subject and its enterprise use. Establish the major concepts, dependencies, ownership boundaries, configuration surfaces and significant execution paths. Choose illustrations after that model is defined. Existing guides and labs provide material to reuse and evidence of current coverage. The subject hierarchy determines the chapter's scope.

L1, L2 and L3 describe how a learner demonstrates competence. Advanced concepts may belong in a chapter even when they are outside its initial assessment target. An exercise demonstrates only the capabilities it samples. Review knowledge completeness against the subject hierarchy, and assess exercise readiness separately.

## Three-layer documentation model

| Layer | Purpose and dependency | Deliverables and acceptance |
|---|---|---|
| A · Knowledge Base | Teach the technical subject in dependency order, starting from prerequisite knowledge. Define responsibilities and explain why each concept exists, when it is used and how it interacts with others. | Definitions, ownership, architecture, internal flow, Mermaid diagrams, configuration semantics, enterprise constraints, misconceptions and synthesis. A reader can explain the normal and significant alternate paths and predict which component owns each decision. |
| B · Practical Reference | Select representative enterprise applications after the relevant concepts and configuration responsibilities are established. | Annotated, unexecuted configuration, commands, UI navigation and permissions where relevant. Explain material lines, defaults, alternatives and change consequences. A reader can predict outcomes and identify dependencies and version assumptions. |
| C · Competency Validation | Assess the capabilities taught by Layers A and B, using the [competency model](docs/competency-levels/00-COMPETENCY-MODEL.md). | Reuse exercises and worked answers. Map L1, L2 and required L3 to prior material, observable evidence and a scoring method. Exercises alone are insufficient for education completion. |

Plan roughly 1,000–2,000 words for a substantial knowledge chapter, with additional diagrams, examples or tables where useful. Allow more room or separate sections when the architecture calls for it. Reuse the existing [concepts and version notes](docs/concepts/README.md), [P0–P5 foundations](docs/concepts/foundations.md), [Windows Shell Runner guide](docs/concepts/windows-shell-runner.md), [architecture](docs/architecture/README.md) and [offline labs](docs/labs/README.md). Use cross-references for shared behavior.

## Learning sequence

Each substantial topic follows this progression:

1. **Concepts and definitions.** Define the problem, purpose, responsibilities, boundaries and nearby terminology for each major concept.
2. **Relationships and usage.** Explain dependencies, alternatives, tradeoffs and enterprise contexts.
3. **Architecture and internal execution.** Plan component, sequence or lifecycle diagrams for normal and significant alternate paths. Distinguish public contracts from version-dependent implementation details.
4. **Configuration and enterprise application.** Explain syntax, defaults, permissions and ownership across GitLab settings, job YAML, runner configuration, Cargo files and Windows where relevant.
5. **Selected illustrations.** Use representative examples to clarify previously taught concepts. Concepts can share an example, and some concepts need only prose or diagrams.
6. **Conclusions and knowledge checks.** Synthesize the relationships and tradeoffs, address misconceptions, ask questions answerable from the chapter and link to related topics for further study.

After studying the chapter and reference, demonstrate L1 by explaining behavior, L2 by reviewing a scoped change and L3, where required, by diagnosing a failure. Apply the offline rubric to the demonstrated capabilities.

L3 is required initially for GitLab lifecycle and configuration, variables, cache and artifacts, Windows runners, integrated delivery, incident diagnosis and readiness. P1, P2 and P7–P10 initially target L2. Their L3 variants are optional and the integrated incident material revisits them.

## Learning tracks

- **Track A · Enterprise survival.** Follow P0 → P3 → P4 → P6, then P5 once Cargo basics are in place. Read the P8–P10 support and result contracts alongside an existing P11 pipeline. Finish with P12 triage and the P13 operator exercise. Use P1.1 and P2.1 when a Cargo or compiler diagnosis requires them.
- **Track B · Read and design from scratch.** P0 → P1 → P2 → P3 → P4 → P5 → P6 → P7 → P8/P9/P10 → P11 → P12 → P13. P7 and the three scanner phases can be scheduled independently after their prerequisites.

## Phase dependencies and study effort

Hours are provisional learner study estimates. Status indicates progress toward the educational criteria below. See the [historical phase status](CURRENT-STATE.md#phase-status) for prior milestones. ⬜ To do · 🟡 In progress · ✅ Education complete

| Phase | Status | Prerequisites | Hours | Exercise mode |
|---|:---:|---|---:|---|
| [P0 · GitLab execution lifecycle](docs/roadmap/P0.md) | 🟡 | — | 2–3 | Offline |
| [P1 · Rust for Java developers](docs/roadmap/P1.md) | 🟡 | P0 | 5–7 | Offline |
| [P2 · Cargo builds and dependency management](docs/roadmap/P2.md) | 🟡 | P1 | 4–6 | Offline |
| [P3 · GitLab CI YAML from zero](docs/roadmap/P3.md) | 🟡 | P0 | 5–8 | Offline |
| [P4 · Variables, roles and secret boundaries](docs/roadmap/P4.md) | 🟡 | P3 | 3–5 | Offline |
| [P5 · Cache, artifacts and reuse](docs/roadmap/P5.md) | 🟡 | P2, P3 | 4–6 | Offline |
| [P6 · Windows Shell runner](docs/roadmap/P6.md) | 🟡 | P3, P4 | 6–9 | Offline |
| [P7 · GitHub Actions migration](docs/roadmap/P7.md) | ⬜ | P5, P6 | 4–6 | Offline |
| [P8 · SonarQube quality and coverage](docs/roadmap/P8.md) | ⬜ | P2, P5, P6 | 4–6 | Offline |
| [P9 · Nexus IQ dependency policy](docs/roadmap/P9.md) | ⬜ | P2, P5, P6 | 3–5 | Offline |
| [P10 · Fortify static security analysis](docs/roadmap/P10.md) | ⬜ | P2, P5, P6 | 4–7 | Offline |
| [P11 · End-to-end enterprise pipeline](docs/roadmap/P11.md) | ⬜ | P4, P5, P6, P8, P9, P10 | 6–10 | Offline |
| [P12 · Enterprise troubleshooting](docs/roadmap/P12.md) | ⬜ | P4–P6, plus P11 for integrated drills | 4–6 | Offline |
| [P13 · Enterprise readiness assessment](docs/roadmap/P13.md) | ⬜ | P7, P11, P12 | 3–5 | Offline |

## Documentation deliverable matrix

Each phase has a defined roadmap and one planned Knowledge Base chapter and Practical Reference. The linked phase files specify paths, evidence, dependencies and acceptance criteria. Prioritize core GitLab and runner coverage, with scanner-specific references completed before integrated delivery.

| Phase and subject | Knowledge Base | Practical Reference | Competency Validation | Target | Existing coverage | Missing work | Priority |
|---|---|---|---|:---:|---|---|:---:|
| [P0 · GitLab execution lifecycle](docs/roadmap/P0.md) | Complete lifecycle architecture and sequence | Annotated YAML and trace atlas | Retain P0.1/.2 and map to lifecycle and evidence | L3 | [Architecture](docs/architecture/README.md) and two trace labs | Expand request/assignment and conditional execution, and publish a trace-to-component reference. | High |
| [P1 · Rust for Java developers](docs/roadmap/P1.md) | Ownership, modules, traits and typed errors | Annotated library/CLI and review diffs | Retain P1.1/.2 and score ownership and safe repair | L2 | [Foundations](docs/concepts/foundations.md#p1--rust-ownership-and-errors) and two Rust labs | Expand modules, visibility, traits and testing, and provide an API and diagnostic review reference. | High |
| [P2 · Cargo builds and dependency management](docs/roadmap/P2.md) | Resolver, feature, build and packaging flows | Workspace, registry and command reference | Retain P2.1/.2 and score graph and output predictions | L2 | [Workspace/lockfile](docs/labs/p2-1-read-cargo-manifests-and-lockfile.md) and packaging labs | Expand resolver, target selection and build/test/package mechanics, and consolidate command choices. | High |
| [P3 · GitLab CI YAML from zero](docs/roadmap/P3.md) | Configuration compilation and DAG model | Line-by-line YAML and keyword reference | Retain P3.1/.2 and score event, edit and failure cases | L3 | [Baseline](docs/labs/p3-1-read-a-complete-gitlab-ci-file.md) and [reusable YAML](docs/labs/p3-2-review-a-reusable-pipeline-graph.md) labs | Unify the existing keyword cards into a systematic reference and expand configuration-evaluation theory. | High |
| [P4 · Variables, roles and secret boundaries](docs/roadmap/P4.md) | Variable lifecycle and access boundaries | UI/role map and protected-variable examples | Retain P4.1/.2 and score eligibility, overrides and diagnosis | L3 | [Precedence](docs/labs/p4-1-review-variable-permissions-and-precedence.md) and scope matrices | Expand trust and evaluation architecture; add a version-qualified read/edit and runner settings access reference. | High |
| [P5 · Cache, artifacts and reuse](docs/roadmap/P5.md) | Cache and artifact storage/transfer model | Cargo cache and provenance reference | Retain P5.1/.2 and score cold/warm and handoff failures | L3 | [Cache](docs/labs/p5-1-diagnose-cargo-cache-behavior.md) and [artifact](docs/labs/p5-2-trace-artifacts-and-dependency-edges.md) labs | Expand storage lifecycle and tradeoffs; consolidate topology and invalidation decisions. | High |
| [P6 · Windows Shell runner](docs/roadmap/P6.md) | Windows service, runner and storage lifecycle | Annotated TOML, YAML, service and PowerShell reference | Retain P6.1/.2 and score routing and service-context triage | L3 | [Windows concept guide](docs/concepts/windows-shell-runner.md) and two runner labs | Extend the guide into a complete lifecycle view including storage; consolidate setup, ownership and service-versus-job settings. | High |
| [P7 · GitHub Actions migration](docs/roadmap/P7.md) | Actions and GitLab event/trust comparison | Complete before/after migration and parity matrix | P7.1 source reading and P7.2 migration review | L2 | [Shared L2 migration excerpt](docs/competency-levels/02-L2-MODIFY.md) and P3 matrix | Dedicated platform model and full before/after workflow including cache, outputs and fork/schedule behavior. | High |
| [P8 · SonarQube quality and coverage](docs/roadmap/P8.md) | SonarQube analysis and gate lifecycle | Version-qualified Rust coverage and gate example | P8.1 report reading and P8.2 gate review | L2 | [Vendor notes](docs/concepts/README.md) and shared gate triage | Dedicated Rust coverage/analysis chapter and annotated version-qualified job, report and gate reference. | Medium |
| [P9 · Nexus IQ dependency policy](docs/roadmap/P9.md) | IQ component and policy lifecycle | Version-qualified Cargo evaluation and outcomes | P9.1 matching and P9.2 enforcement review | L2 | [Vendor notes](docs/concepts/README.md) and shared gate triage | Dedicated Rust component and policy lifecycle chapter plus annotated integration and result reference. | Medium |
| [P10 · Fortify static security analysis](docs/roadmap/P10.md) | Fortify scan modes, source boundaries and policy | Version-qualified Rust SAST and findings reference | P10.1 scan-path reading and P10.2 gate review | L2 | [Vendor notes](docs/concepts/README.md) and shared gate triage | Dedicated architecture and Rust capability chapter plus reviewed integration and findings reference. | Medium |
| [P11 · End-to-end enterprise pipeline](docs/roadmap/P11.md) | Integrated graph, trust and release architecture | Annotated end-to-end enterprise example | P11.1 graph and change review, P11.2 release incidents | L3 | [Subsystem labs](docs/labs/README.md) and [enterprise scenarios](docs/enterprise-scenarios/README.md) | Dedicated integrated architecture and coherent end-to-end example with compatible assumptions and gates. | High |
| [P12 · Enterprise troubleshooting](docs/roadmap/P12.md) | Structured incident and recovery model | Annotated trace and evidence reference | P12.1 runner and P12.2 multi-domain drills | L3 | [Troubleshooting index](docs/troubleshooting/README.md) and [worked incidents](docs/competency-levels/03-L3-TROUBLESHOOT.md) | Expand the structured triage method and integrate an evidence pack across failure domains. | High |
| [P13 · Enterprise readiness assessment](docs/roadmap/P13.md) | Readiness, calibration and evidence model | Operational checklists and assessor guide | P13.1 operator and P13.2 builder assessments | L3 | [Readiness rubric](assessments/README.md) and [competency rubric](docs/competency-levels/04-SUMMARY-VALIDATION.md) | Add a unified learner/assessor path, scored integrated evidence and explicit treatment of distinct rubrics. | High |

## Educational completion criteria

| Status | Required evidence |
|---|---|
| **ROADMAP DEFINED** | Scope, prerequisite knowledge, deliverables and bounded steps exist. |
| **KNOWLEDGE COMPLETE** | Layer A covers the subject hierarchy, relationships, normal and significant alternate paths, configuration boundaries, misconceptions, synthesis and knowledge checks. Coverage is evaluated independently of the exercises. |
| **REFERENCE COMPLETE** | Layer B illustrates established concepts with representative configurations, syntax, defaults, access requirements and safe alternatives. |
| **VALIDATION READY** | Layer C maps the required levels to taught material and has sufficient fixtures, worked answers and assessment criteria. |
| **EDUCATION COMPLETE** | All three layers satisfy their criteria, and diagrams, configuration, scenarios and answers agree. |
| **LIVE VALIDATION DEFERRED** | Infrastructure and runtime verification are tracked separately in [Future labs](FUTURE-LABS.md). |

P0.1–P6.2 remain completed under their original scope. The [progress log](CURRENT-STATE.md) preserves that historical documentation status. Under the new criteria, P0–P6 are in progress while their layer expansions and alignment reviews are pending. P7–P13 have defined roadmaps and reusable supporting material where listed. Live validation is deferred across all phases.

## Minimum viable enterprise readiness

For work on an existing pipeline, start with the subject hierarchies for the relevant phases, then demonstrate that you can trace a job, review a YAML change, explain a variable's scope, distinguish a stale cache from a missing artifact, and diagnose Cargo lookup under the Windows service identity. Then interpret the three gate outcomes from an existing trace and diagnose one incident. Use P0.1, P1.1, P2.1, P3.2, P4.2, P5.1–2, P6.2, read-only portions of P8–P11, P12.1 and the P13.1 operator exercise. Use illustrative or sanitized configurations, job graphs and traces as inputs.

## Next documentation task

Start with **[P0.A](docs/roadmap/P0.md#p0a--develop-the-knowledge-base-chapter)** to expand the shared job lifecycle model that later GitLab and runner phases build on. For the migration track, P7.A → P7.B now precede the previously queued P7.1. Each phase closes with its Layer C coverage review.
