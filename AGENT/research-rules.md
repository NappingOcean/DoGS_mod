# Research and verification rules

These rules apply to DoGS source research, implementation, and documentation.

## Resolve identifiers before interpreting behavior

Do not infer an unclear constant's meaning from its name or abbreviation. Find its JSON definition and inspect names, descriptions, properties, and copy-from inheritance. Trace the loader and the C++ enum or binding when the ID is not JSON-defined. If its meaning remains unresolved, state that explicitly.

Check the actual creature definition and inherited material/flags before applying a general condition to that creature. For example, materials.json defines iflesh as Insect Flesh; mon_zombie uses flesh with WARM. The presence of iflesh in an immunity branch does not make it a zombie material.

## Follow the full execution path

Inspect the loader, runtime state, callback dispatch, action costs, immunity checks, and save/load paths relevant to a claim. Verify binding signatures and return semantics rather than relying on function names. Consider mod load order and replacement behavior.

Do not equate source support with a working DoGS implementation. An existing test definition is evidence of coverage intent; it is not evidence that the test was run.

## Record evidence and uncertainty

Record the BN revision and repository-relative source locations. Prefer links pinned to that revision. Separate:

- Confirmed source behavior
- Runtime test results, including the actual environment and commands used
- Design decisions and implementation candidates
- Unresolved questions or tests blocked by missing implementation

Keep concrete findings in docs, and keep reusable working rules here. When correcting a claim, update its English and Korean versions and related summaries.

## Validate changes

Run checks appropriate to the change. For documentation, verify links and formatting. For JSON or Lua implementation, validate loading and the relevant behavior in BN. Document unperformed or blocked runtime checks without presenting them as completed.

## Shared and local context

Commit project-wide rules. Keep personal paths, credentials, environment-specific settings, and temporary investigation notes local. Shared guidance should use logical or repository-relative paths.

## Commit attribution

Include `Assisted-by: OpenAI GPT` in commits containing GPT-assisted work.
