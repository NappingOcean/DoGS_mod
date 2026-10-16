# DoGS agent instructions

Read [AGENT/research-rules.md](AGENT/research-rules.md) before investigating BN behavior, changing the mod, or updating technical documentation.

For the current state, design, roadmap and experiment log, start at [docs/en/index.md](docs/en/index.md) (Korean: [docs/ko/index.md](docs/ko/index.md)). The mod lives in `DoGS_mod/`.

- Target Cataclysm: Bright Nights and identify the source revision used for verification.
- Current reference target: `f9586ef033948451f9c5a136d1ce6214198f1a67`, matching redhot build `2026-10-16-0238`. Keep reference checkouts pinned to the installed game revision; older audit documents retain their stated historical revisions.
- Resolve unclear constants and IDs through their JSON definitions, inheritance, and loaders before assigning meaning.
- Distinguish design decisions, source-confirmed behavior, and runtime-tested behavior.
- Keep English and Korean documentation aligned.
- Keep machine-specific paths and temporary notes out of shared instructions.
