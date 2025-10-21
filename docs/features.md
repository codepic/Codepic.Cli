# Codepic CLI Features

This document summarizes the major feature areas that make up the Codepic CLI experience and highlights the sub-features that keep the tooling consistent across workstations and automation environments.

## Bootstrapper

The bootstrapper (`./.build.ps1` together with the `init` task) delivers a predictable entry point for every session.

- **Invoke-Build bootstrap** — Ensures Invoke-Build is available, then re-invokes itself so every discovered task runs under the same orchestration engine, locally or in CI.
- **Alias provisioning** — `Invoke-AliasSetup` registers a user-chosen alias in the PowerShell profile and reloads it, giving contributors a short, memorable command surface.
- **Task discovery** — Recursively loads every `*.tasks.ps1` file so new modules become available without manual wiring or script edits.
- **Environment awareness** — Detects Azure DevOps (`TF_BUILD`) and other CI contexts to install prerequisites safely, while keeping logging clear about what happened.

## CLI Modules

Modules are the units of automation. They package tasks, instructions, and helper logic so capabilities stay portable.

- **Declarative manifests** — `module.manifest.json` follows the schema in `docs/module-manifest.md`, documenting include/exclude paths, install instructions for humans and copilots, and source metadata for cloning or updates.
- **Lifecycle commands** — Tasks such as `clone-module`, `update-module`, `pack-module`, `unpack-module`, and `remove-module` manage artifacts via tag-aware git clones and `./dist/<module>/<module>.<version>.zip` packaging.
- **Root module** — The baseline module located at `modules/.tasks.ps1` ships reusable tasks (`lint`, `lint-fix`, `init`, packaging flows) that other modules can rely on when they are bootstrapped by the CLI.
- **Task-specific functions** — Shared helpers in `modules/.tasks.functions.ps1` keep Invoke-Build tasks terse and readable while encapsulating logic such as alias setup.

## Instructions Framework

Instruction files under `.github/instructions/` define the governing rules that keep modules and tasks consistent.

- **Build and task guidance** — `.build.instructions.md`, `.tasks.instructions.md`, and `.tasks.functions.instructions.md` capture required structure, logging conventions, and helper expectations for scripts and Invoke-Build tasks.
- **Alignment protocol** — `.protocol.alignment.instructions.md` introduces a gated decision workflow so contributors and assistants resolve ambiguities before altering conventions.
- **Prompt catalog** — `.github/prompts/.new-module.prompt.md` primes copilots with repository-specific scaffolding steps, ensuring automated assistance mirrors human expectations.
- **Logging conventions today** — The logging rules live in `.tasks.instructions.md` (for example, `Write-Build` color usage and `exec {}` wrappers). They can evolve into a dedicated logging framework as provider support and centralized collection mature.

## Enablers

Enablers represent optional tooling and integrations that the slim core orchestrates without bundling directly into the CLI. See `docs/enablers.md` for the process of introducing new capabilities.

- **Slim core guarantee** — The bootstrapper remains lean; enablers add Terraform, Bicep, or other stacks only when modules demand them.
- **Opt-in installation** — Each enabler documents how humans and agents acquire prerequisites so the CLI avoids imposing global dependencies.
- **Lifecycle governance** — Contributors follow the enabler lifecycle to register tasks, update instruction files, and keep CI parity before shipping new optional tooling.

## Future Opportunities

The current framework already provides portability, documentation, and guided automation. Future enhancements can build on these foundations—for example, expanding the logging conventions into a formal logging framework with pluggable providers for centralized telemetry, or extending module manifests with richer lifecycle metadata once new scenarios demand it.
