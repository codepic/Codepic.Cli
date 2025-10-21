# Enablers

Enablers describe optional tooling, runtimes, and integrations that the Codepic CLI orchestrates without bundling directly into the core. They keep the CLI slim while letting contributors bring in the stacks they need (for example Terraform, Bicep, or other cloud-specific toolchains).

## Philosophy

- **Slim core, optional edges** — The CLI focuses on orchestration, task discovery, and packaging. Enablers supply the domain-specific tooling that different teams require.
- **Local-first flow** — Each enabler must support the feedback-loop principles in `docs/background.md`: fast local iteration, actionable output, and parity with CI environments.
- **Documented entry points** — Operators and agentic assistants should understand when and how to install an enabler before invoking tasks that depend on it.

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
