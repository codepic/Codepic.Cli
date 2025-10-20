# Codepic CLI Background

## Origin Story

The Codepic CLI grew out of frustration with the traditional edit > commit > push > wait-for-pipeline loop. Shipping even small changes meant context switching between writing code, watching remote builds, and deciphering vague logs. Flow state evaporated, iteration slowed, and the tools meant to help automation engineers actually kept them out of automation.

Those frustrations were amplified whenever the pipeline only failed on a different operating system. Setting up ad-hoc Linux virtual machines just to reproduce a bash script felt like solving infrastructure cosplay instead of solving the actual problem. The long-term fix had to be a CLI that gave me a single command to paste locally, hit a breakpoint, and inspect the state without detouring through a hypervisor.

The other recurring drag was the so-called "setup guide"—a novella-length checklist of SDK installs, environment variables, and tribal knowledge. By the time everything was configured, the original bug felt like ancient history. I wanted the opposite: clone the repo, open an editor, run a couple of tasks, and get moving. If the toolchain needs to exist, `.build.ps1` should fetch it; the operator shouldn't have to audition for an operations role just to reproduce an issue.

Even well-meaning documentation rarely kept pace with the tooling. A wiki page declared "it just works" until the day it didn’t. So the CLI needed to become the documentation: if I can type `codepic ui deploy dev`, and the bootstrapper lines up the dependencies, that command becomes living guidance. Comment-based help and `Get-Help` output close the discoverability gap, but the real win is shrinking knowledge transfer down to a single, memorable incantation.

And then there was the spaghetti. Giant PowerShell scripts with inconsistent formatting, dead code, and duplicated pipeline logic telegraphed that ten different people had patched them in ten different styles. Finding a failure felt like spelunking. I wanted each module to read the same way every time, so when something broke you could already picture which task block to inspect before opening the editor. Consistent structure plus helper functions meant fewer scavenger hunts and more fixes.

Dependency hell was the final straw. Every pipeline seemed to invent its own dance of "install this here, but only on the first run, unless that other job already did it." A massive thank-you to [Roman Kuzmin](https://github.com/nightroman) for [Invoke-Build](https://github.com/nightroman/Invoke-Build), which finally gave me a declarative way to express prerequisites once and let the engine guarantee they run exactly where needed—no more shell scripts copy-pasted across YAML files.

Communication was just as messy. Everyone had their own vocabulary for modules—"Is this the deploy script or the publish step?"—and the answer changed depending on who wrote it. We needed a domain language baked into the CLI so saying "this module supports build and test" instantly implied which commands would run and which outputs to expect. Shared task names, consistent verbs, and help documentation turned hallway conversations into quick terminal sessions.

Once the CLI behaved the same on any developer machine, the final step was obvious: lift it wholesale into a Dockerfile. Instead of writing bespoke shell scripts for each platform, we build an image that already includes the CLI, drop the familiar commands into the Dockerfile, and ship it. If it works locally, it works in GitHub, Azure DevOps, GitLab—no iterative Docker fiddling required.

That convergence led to a non-negotiable rule: wrapping a capability as a module or task must always be the fastest way to get work done. If ad-hoc scripting ever feels quicker, we treat it as a bug in the CLI experience and fix the tooling until the structured path wins again.

## Guiding Philosophy

We design every module, task, and helper with a **local-first feedback loop** mindset. Contributors should tighten their change-test cycle on their own workstation, validate assumptions immediately, and only use pipelines for confirmation, not discovery. If a task fails remotely, it should do so because it *already* fails locally.

## Core Principles

- **Immediate feedback**: Provide linting, packaging, and module lifecycle tasks that run locally with clear, deterministic outcomes.
- **Flow preservation**: Keep commands low-noise and reusable so developers stay focused; automation should eliminate dead time instead of creating it.
- **Actionable output**: Emit human-friendly messages (`Write-Build`, structured errors) that point directly to the fix, whether running locally or in CI.
- **Consistent guardrails**: Instruction files and manifests form the contract; enforcing them locally avoids back-and-forth with code reviews or pipelines.
- **Portability by default**: Scripts assume minimal prerequisites, install what they need, and remain cross-platform so the same workflow works on every machine.
- **Copy-paste reproducibility**: Every pipeline action should boil down to a documented command that runs identically on Windows, Linux, or macOS, making debugger-friendly reproductions the norm.
- **Predictable layout**: Tasks and helpers follow the same patterns across modules so failures are easy to triage and fixes land in the right place the first time.
- **Explicit dependencies**: Tasks declare their prerequisites, and the bootstrapper orchestrates them through Invoke-Build so modules never drift out of sync.
- **Shared vocabulary**: Modules expose the same verbs and help patterns, giving teams a common language for build, test, deploy, and beyond.
- **Pipeline parity**: The CLI runs identically on workstations and inside containers, so any platform capable of pulling the image can execute the same automation.
- **Accelerated scaffolding**: Creating a new module or task is intentionally faster than hacking one-off scripts; efficiency is the barometer for every expansion.

## Success Criteria

We know the CLI is doing its job when:

- Engineers rarely rely on pipeline retries to discover issues.
- Task logs read like guidance, not puzzles.
- New contributors can get productive within a single session by following the documented conventions.
- Module authors ship artifacts confidently because the local packaging flow matches production expectations.

## Looking Ahead

As the CLI evolves, additions should start by asking: *Will this help someone stay in flow?* If the answer is yes, capture the decision in `docs/background.md` and update accompanying instructions so the rationale remains clear to the next contributor who wonders why the repository feels opinionated about automation.
