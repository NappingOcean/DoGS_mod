# DoGS agent instructions

Read [AGENT/research-rules.md](AGENT/research-rules.md) before investigating BN behavior, changing the mod, or updating technical documentation.

- Target Cataclysm: Bright Nights and identify the source revision used for verification.
- Current reference target: `ef0eceda391d4d291b366e3bf2833b04c7342d72`, matching redhot build `2026-10-04-0345`. Keep reference checkouts pinned to the installed game revision; older audit documents retain their stated historical revisions.
- Resolve unclear constants and IDs through their JSON definitions, inheritance, and loaders before assigning meaning.
- Distinguish design decisions, source-confirmed behavior, and runtime-tested behavior.
- Keep English and Korean documentation aligned.
- Keep machine-specific paths and temporary notes out of shared instructions.
