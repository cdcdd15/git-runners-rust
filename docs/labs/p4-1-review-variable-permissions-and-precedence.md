# P4.1 · Review GitLab variable permissions and precedence

**Access** — Offline. Allow 45–60 minutes. Start with the [P3.2 event and job graph review](p3-2-review-a-reusable-pipeline-graph.md). The configuration, settings, permissions scenario and expected outputs below are illustrative and unexecuted. All values are synthetic and nonsecret.

Ledger Gateway's Windows validation job uses `LEDGER_LAB_MODE` to select a reporting mode. A maintainer expects the job's YAML value to win, but a project setting supplies another value. Review the effective job, the event, and the owners of the possible overrides. This is similar to reviewing Spring property sources, with an additional distinction between the time GitLab creates the job graph and the time Runner starts the shell.

## Read the settings and identify the owner

| Surface | Where to inspect it | Who can change it or supply a value |
|---|---|---|
| Project variable | Project → **Settings → CI/CD → Variables** | GitLab documents project Maintainer for adding and updating project variables. This applies to the project's settings, independently of permission to edit the repository. |
| Group or subgroup variable | Open the specific group or subgroup → **Settings → CI/CD → Variables** | GitLab documents group Owner for adding and updating variables in that namespace. A project Maintainer may need the subgroup owner to review an inherited definition. |
| Instance variable | Self-managed instance **Admin → Settings → CI/CD → Variables** | Instance administrator. Check offering and installed version before assuming this surface exists. |
| Pipeline variable | **Build → Pipelines → New pipeline** for a UI run. Also inspect schedules, API calls, push options and upstream forwarding when relevant. | For a UI run, check pipeline-run permission, ref access and the project's **Minimum role to use pipeline variables** setting. A permitted pipeline run does not automatically authorize an override. |
| Repository variable | The job, its parents, matching rules and defaults in the effective YAML | Contributors can propose a repository change. Approval and merge permissions depend on the target ref and project controls. |
| Manual job variable | The form for starting an existing manual job, where available | Check who can run that job and any protected environment restrictions. Treat this as an override on that job, separate from values supplied at pipeline creation. |

GitLab documents `developer`, `maintainer`, `owner` and `no_one_allowed` for the project minimum-role setting. A Maintainer can generally change it, while changing an existing `owner` or `no_one_allowed` setting requires Owner. Defaults depend on the offering, version and namespace history. Check the deployed version and effective role instead of inferring access from a missing Settings menu. [GitLab CI/CD variables](https://docs.gitlab.com/ci/variables/), [GitLab roles](https://docs.gitlab.com/user/permissions/), [manual jobs](https://docs.gitlab.com/ci/jobs/job_control/)

## Decide when the value is needed

1. **Configuration and graph creation.** Inputs are validated and interpolated into the configuration. Workflow and job rules evaluate using variables available at their respective evaluation points. A producer's runtime output is unavailable to those rules.
2. **Prepare the job environment.** Identify definitions eligible for the ref, environment and job. Apply precedence among eligible sources. A protected or scoped value can be absent even though it has higher precedence on paper. [P4.2](../roadmap/P4.md#p42--review-secret-and-scope-boundaries) examines those eligibility boundaries.
3. **Shell execution.** PowerShell reads the resulting environment with `$env:LEDGER_LAB_MODE`. A shell assignment can change the value for subsequent commands in that shell. It cannot retroactively change the graph or propagate to a separate job by itself. A YAML value containing another variable reference is a separate expansion question. Check the keyword and expansion settings for the GitLab, Runner or shell layer that handles it. [Predefined variable availability](https://docs.gitlab.com/ci/variables/predefined_variables/), [variable expansion](https://docs.gitlab.com/ci/variables/where_variables_can_be_used/)

## Precedence review card

Read the current public GitLab order from strongest to weakest for an eligible key. Use the documentation matching the deployed version when reviewing older configurations, especially policy and manual overrides. This lab has no policy or manual job overrides.

| Priority | Source |
|---:|---|
| 1 | Applicable pipeline execution or scan execution policy variables |
| 2 | Variables supplied when starting a manual job |
| 3 | Pipeline variables supplied at creation or forwarded into the pipeline |
| 4 | Project variables |
| 5 | Group variables, with the closest subgroup winning a group collision |
| 6 | Instance variables |
| 7 | Variables inherited from an eligible upstream dotenv report |
| 8 | YAML variables, in order: matching job `rules:variables`, job `variables`, matching `workflow:rules:variables`, top-level `variables` |
| 9 | Deployment variables |
| 10 | Predefined variables, with documented exceptions that cannot be overridden |

Inputs have their own configuration-time contract. External secrets retrieved by Runner are also outside this precedence table. Avoid overriding predefined variables when designing job controls. [GitLab variable precedence](https://docs.gitlab.com/ci/variables/#cicd-variable-precedence)

## Complete illustrative configuration

Assume the same Windows Shell runner as P3, with PowerShell Core. This file demonstrates precedence with a single nonsecret key. The probe prints only this fixture key and uses an allowlist so arbitrary values are not written to the trace.

```yaml
workflow:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "web"'
      variables:
        LEDGER_LAB_MODE: "workflow-web"
    - if: '$CI_PIPELINE_SOURCE == "push" && $CI_COMMIT_BRANCH'

variables:
  LEDGER_LAB_MODE: "yaml-default"

stages: [prepare, inspect]

publish_mode:
  stage: prepare
  tags: [windows-rust]
  rules:
    - if: '$CI_PIPELINE_SOURCE == "web"'
  script:
    - Set-Content -LiteralPath mode.env -Value 'LEDGER_LAB_MODE=generated' -Encoding ascii
  artifacts:
    reports:
      dotenv: mode.env

inspect_mode:
  stage: inspect
  tags: [windows-rust]
  variables:
    LEDGER_LAB_MODE: "yaml-job"
  rules:
    - if: '$CI_PIPELINE_SOURCE == "web"'
      variables:
        LEDGER_LAB_MODE: "yaml-web-rule"
    - if: '$CI_PIPELINE_SOURCE == "push" && $CI_COMMIT_BRANCH'
  needs:
    - job: publish_mode
      optional: true
      artifacts: true
  script:
    - |
      $allowed = @('pipeline', 'project', 'subgroup', 'group', 'instance',
                   'generated', 'yaml-web-rule', 'yaml-job',
                   'workflow-web', 'yaml-default')
      if ($env:LEDGER_LAB_MODE -cnotin $allowed) {
        throw "Missing or unexpected lab mode"
      }
      Write-Host "Mode: $env:LEDGER_LAB_MODE"
```

The web producer writes the constant `generated`, independent of its own effective variable value. The consumer receives that report through the `needs` edge, but dotenv has lower precedence than eligible project, group, instance and pipeline variables. In a branch-push pipeline the producer is absent, and the optional edge lets the consumer run without it. Keep credentials out of dotenv reports and downloadable job artifacts. [GitLab dotenv variables](https://docs.gitlab.com/ci/variables/dotenv_variables/), [artifact reports](https://docs.gitlab.com/ci/yaml/artifacts_reports/#artifactsreportsdotenv)

## Work the collision matrix

Assume the project belongs to `Platform / Ledger / Gateway`. The parent group defines `group`, the closest subgroup defines `subgroup`, and the project defines `project`. Assume an instance value `instance` exists for this fixture. These settings are all eligible, unprotected and unscoped. Each row applies only the stated changes to that baseline.

| Event and changes | Expected consumer value | Deciding evidence |
|---|---|---|
| Branch push, all settings present | `project` | Project outranks the subgroup and job YAML. |
| Web run with an authorized pipeline variable set to `pipeline` | `pipeline` | The run-level override wins over project and dotenv. |
| Web run, no pipeline or project value | `subgroup` | The closest group beats the parent group, instance and dotenv. |
| Web run, neither group nor project has the key and no pipeline value is supplied | `instance` | The instance value outranks dotenv. |
| Web run, no settings or pipeline value | `generated` | The upstream dotenv report beats all four YAML layers. |
| Same web run, but the consumer disables artifact transfer on the edge | `yaml-web-rule` | The report is unavailable and the matching job rule overrides job, workflow and top-level YAML. |
| Branch push, no settings or pipeline value | `yaml-job` | The producer and web rule are absent. Job YAML beats the top-level default. |

## Review questions and worked answers

1. **The UI rejects a Developer's attempt to supply an override. Is this a precedence failure?**  
   **Answer** — Check the project's minimum role and whether the user can run on the selected ref. A rejected submission never supplies a candidate value. Changing YAML precedence cannot authorize the request.
2. **A job must use the generated mode to decide whether it appears in the pipeline. Can it use the dotenv key in `rules:if`?**  
   **Answer** — The job graph is already built before the producer runs. Use a configuration-time input or evaluate the generated data inside a job that is already selected.
3. **Why does the web workflow value lose even when the report is absent?**  
   **Answer** — The matching job rule defines the key, and job-level variables also outrank workflow variables. If the report, job rule's value and job-level value were all removed, the matching web workflow value would beat the top-level default.
4. **A trace says `Mode: subgroup` after the project definition is removed. Who owns the next settings change?**  
   **Answer** — The closest subgroup owns the winning definition. Ask its group Owner to review whether it should apply across descendant projects. A project-specific exception has a different blast radius and belongs to the project settings owner.

## Acceptance

Name the winning source and the evidence for each row. Identify who can review or change it, explain why dotenv cannot influence job creation, and distinguish a rejected override from an accepted value that loses precedence. [Future labs](../../FUTURE-LABS.md) track runtime verification separately.
