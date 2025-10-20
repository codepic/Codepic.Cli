# Module Manifest Specification

The Codepic CLI relies on a declarative manifest (`module.manifest.json`) to describe every module packaged under `modules/`. This document defines the canonical schema and supporting rules so packaging, clone, update, and removal tasks remain predictable.

> ℹ️ **JSON Schema**: Manifests may declare the published schema for editor IntelliSense and validation by adding the following to the top of the file:
> ```json
> {
>   "$schema": "https://raw.githubusercontent.com/codepic/Codepic.Cli/main/schema/cli/module-manifest/v1/schema.json",
>   ...
> }
> ```

## Purpose

- Provide a single source of truth for the files and metadata that form a module artifact.
- Enable tooling (`pack-module`, `unpack-module`, `clone-module`, `update-module`, `remove-module`) to operate without bespoke logic per module.
- Guarantee that contributors can reason about module contents, provenance, and distribution by reading a small JSON document checked into source control.

## Required Fields

| Field         | Type             | Description                                                                                                                |
| ------------- | ---------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `name`        | string           | Lowercase identifier matching the module directory name under `modules/`.                                                  |
| `version`     | string           | Semantic version of the module artifact (for example `0.1.0`).                                                             |
| `description` | string           | Short human-readable summary of the module’s purpose.                                                                      |
| `include`     | array of strings | Repository-relative paths that must be present when packaging or restoring the module. Always include the manifest itself. |

## Optional Fields

| Field       | Type             | Description                                                                                                                                               |
| ----------- | ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `$schema`   | string           | Optional reference to the published JSON schema (`https://raw.githubusercontent.com/codepic/Codepic.Cli/main/schema/cli/module-manifest/v1/schema.json`). |
| `install`   | object           | Optional onboarding guidance surfaced by tooling. Recognized properties live under `install.instructions`.                                               |
| `exclude`   | array of strings | Repository-relative paths to omit after `include` resolution. Useful when a directory contains generated or local-only files.                             |
| `source`    | object           | Metadata describing the canonical origin of the module. Recognized properties:                                                                            |
| `git`       | string           | Repository URL used by `clone-module`/`update-module` when a caller does not provide `-Git`.                                                              |
| `tagPrefix` | string           | Optional prefix (defaults to `v`). The tooling concatenates this value with the requested `-Version` when checking out tags.                              |

### `install.instructions`

- `human` — Freeform text shown to operators performing the installation manually.
- `copilot` — Guidance for automated assistants that may execute installation steps on the user’s behalf.

## Path Semantics

- Paths in `include` and `exclude` are evaluated relative to the repository root.
- Use forward slashes for consistency across Windows and Unix-like systems.
- When specifying directories, ensure the path ends without a trailing slash (`modules/sample` instead of `modules/sample/`).

## Packaging Behaviour

- `pack-module` creates `./dist/<module>/<module>.<version>.zip` using the paths declared in `include` minus any entries filtered by `exclude`.
- Legacy `Module.zip` artifacts are deleted during packaging to avoid ambiguity.
- `unpack-module` restores artifacts by expanding the zip into a temporary directory and copying the manifest’s `include` list back into the repository.

## Clone and Update Behaviour

- `clone-module` expects to find a manifest inside the remote repository whose `name` and `version` match the supplied arguments. The `include` list is copied into the local workspace verbatim.
- `update-module` removes the previous `include` set before laying down the requested version. If `source.git` is absent, callers must provide `-Git` explicitly.
- Both commands honor `source.tagPrefix` when constructing the tag name (`<tagPrefix><Version>`).

## Example Manifest

```json
{
  "name": "sample",
  "version": "0.2.0",
  "description": "Example module demonstrating Codepic CLI conventions.",
  "include": [
    "modules/sample/.tasks.ps1",
    "modules/sample/module.manifest.json",
    "modules/sample/module.tasks.instructions.md"
  ],
  "exclude": [
    "modules/sample/local.settings.json"
  ],
  "source": {
    "git": "https://github.com/codepic/Codepic.Cli.Sample.git",
    "tagPrefix": "v"
  }
}
```

## Implementation Checklist

When authoring or reviewing a manifest:

1. Confirm the manifest resides in the module directory (`modules/<name>/module.manifest.json`).
2. Ensure `name` matches the directory and is lowercase.
3. Verify every `include` path exists in the repository and that the manifest itself is listed.
4. Remove obsolete files by declaring them in `exclude` or deleting them at the source.
5. Update `version` alongside `dist` artifacts so consumers can track releases.
6. Provide `source.git` whenever a module originates from an external repository.
