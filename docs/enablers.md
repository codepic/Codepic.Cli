# Enablers

Enablers describe optional tooling, runtimes, and integrations that the Codepic CLI orchestrates without bundling directly into the core. They keep the CLI slim while letting contributors bring in the stacks they need (for example Terraform, Bicep, or other cloud-specific toolchains).

## Philosophy

- **Slim core, optional edges** — The CLI focuses on orchestration, task discovery, and packaging. Enablers supply the domain-specific tooling that different teams require.
- **Local-first flow** — Each enabler must support the feedback-loop principles in `docs/background.md`: fast local iteration, actionable output, and parity with CI environments.
- **Documented entry points** — Operators and agentic assistants should understand when and how to install an enabler before invoking tasks that depend on it.

## Prerequisites vs. Enablers

- **Prerequisites** are the non-negotiable foundations the CLI depends on everywhere (for example PowerShell 7+, Invoke-Build, Git). They belong in onboarding docs and bootstrap checks because every module requires them.
- **Enablers** are optional toolchains layered on top of the prerequisites. Modules may opt in to Terraform, Bicep, container CLIs, or other stacks without inflating the base install.
- Keep prerequisites documented separately (for example in `README.md` or module onboarding notes) so contributors know what must exist before any CLI command succeeds.
- When a prerequisite evolves into an optional scenario, move it into the enabler catalogue and document the opt-in lifecycle below.

## What Qualifies as an Enabler

An asset should be treated as an enabler when it meets at least one of these criteria:

- Provides external tooling or SDKs that are not universally required by every module.
- Extends automation into third-party platforms (for example infrastructure-as-code engines or language runtimes).
- Introduces integrations that warrant opt-in setup, licensing, or environment prerequisites.

## Lifecycle for Adding an Enabler

1. **Assess fit** — Confirm the addition aligns with the CLI philosophy and does not bloat the bootstrapper.
2. **Describe the capability** — Update this document with a short summary of the enabler, the problems it solves, and any supported providers or versions.
3. **Define tasks and helpers** — Create dedicated tasks or helper functions inside the relevant module so operators can invoke the enabler consistently.
4. **Update instructions** — Extend the applicable instruction files (for example `.tasks.instructions.md`) with usage rules, logging expectations, and testing guidance.
5. **Clarify installation** — Document how humans and copilots acquire or configure the enabler (manual steps, package managers, or manifest `install.instructions`).
6. **Validate portability** — Ensure CI and container workflows can install or simulate the enabler so pipeline parity remains intact.

## Tracking Enablers

When you introduce a new enabler, add a subsection in this document that records:

- **Name** and short description.
- **Owning module** and task entry points.
- **Prerequisites** (install commands, environment variables, credentials).
- **Testing guidance** (linting, validation tasks, integration checks).

Keeping this inventory current helps maintain transparency around optional dependencies and allows future contributors to evaluate reuse versus creating a new module.

### Azure CLI (`azcli`)

- **Owning module**: Root module (`enabler:install`, `enabler:upgrade`, `enabler:remove` tasks exposed via `codepic . install-enabler`, `upgrade-enabler`, `remove-enabler`).
- **Purpose**: Verifies Azure CLI availability, provides an upgrade helper, and surfaces manual uninstall guidance.
- **Prerequisites**: PowerShell 7+, Git, and Azure CLI installed per [official docs](https://learn.microsoft.com/cli/azure/install-azure-cli).
- **Testing guidance**: Run `codepic . install-enabler -Enabler azcli -Version <tag> -Git <repo>` followed by `codepic . upgrade-enabler -Enabler azcli -Version <tag>` to confirm lifecycle tasks succeed. Validate removal with `codepic . remove-enabler -Enabler azcli`.
- **Binary lookup**: Command name `az`. Expected locations include `%ProgramFiles%\Microsoft SDKs\Azure\CLI2\wbin\az.cmd` (Windows), `/usr/bin/az` and `/usr/local/bin/az` (most Linux distros), and `/usr/local/bin/az` or `/opt/homebrew/bin/az` (macOS).
