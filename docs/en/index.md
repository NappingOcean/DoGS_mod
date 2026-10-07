# DoGS documentation

[한국어](../ko/index.md)

**DoGS — Dogs of Good Sense** turns dogs in Cataclysm: Bright Nights (BN) into tactical companions that judge the situation. It does not make dogs stronger; it adds judgment about position, risk and when to step in.

## Status (2026-10-07)

- Implementation: [`DoGS_mod/`](../../DoGS_mod/), for one dog type, the Labrador mutt (`mon_dog`). It runs as a judgment layer over BN's stock pet AI.
- Behavior: a safety veto (encirclement avoidance, falling back behind the player at low HP), Takedown and Ankle Tear control attacks, and roles (Guard by default; Free and Harass selectable, Harass at v0). Training and role are set per dog in the action menu.
- Verification: experiments E0–E7 are done. E7 largely confirmed the new Takedown resolution (applied from Lua, resisted by size); miss detection is still unverified. Harass v0 has not been checked in play yet (E8 rerun planned).
- Next steps: [roadmap](roadmap.md).

## Reading order for a new session

1. This page
2. [Philosophy](philosophy.md): the user's principles; the yardstick for every decision
3. [Behavior design](design.md): how the dog judges now
4. [Roadmap](roadmap.md): what is done and what comes next
5. As the task requires: [control attacks](attacks.md), [engine notes](engine-notes.md), [development guide](development.md), [experiments](experiments.md), [Harass role](harass.md)
6. Research and implementation rules: [AGENT/research-rules.md](../../AGENT/research-rules.md)

## Document map

| Document | Contents |
| --- | --- |
| [philosophy.md](philosophy.md) | Goals, design principles, trained-dog behavior |
| [design.md](design.md) | Decision order, states and transitions, safety veto, roles, planned behavior, known limits |
| [attacks.md](attacks.md) | Intent, numbers and resolution of Takedown and Ankle Tear |
| [harass.md](harass.md) | The Harass role: delaying the next enemy (v0 implemented, not yet checked in play); difference from Guard, open points, shelved idea |
| [engine-notes.md](engine-notes.md) | BN behavior the implementation relies on, with source locations and runtime status |
| [development.md](development.md) | Code layout, coding rules, per-entity values, configuration, logging, install and check, experiment procedure |
| [experiments.md](experiments.md) | Experiment list, procedures and results |
| [roadmap.md](roadmap.md) | Status, next steps, open questions, decision log |
| [source-verification.md](source-verification.md), [combat-hooks.md](combat-hooks.md) | Codex's earlier source audits (revision `e0e25e9`), kept as historical records |

## Notation

Following AGENTS.md, evidence is labeled by kind.

- **[design]** A decision made with the user; experiments may change it.
- **[source]** Behavior confirmed in BN source at the revision below.
- **[runtime E#]** Behavior confirmed in a play log; the number points to [experiments](experiments.md).
- **unverified** Not yet confirmed in source or play.

## Basis

- Game: redhot build `2026-10-07-0423`, BN commit `31a958998ac2bb53aca592e06eb4010d9dc1746a` (the reference revision in AGENTS.md).
- Source claims recorded at `8e8aa90` (redhot `2026-10-05-2327`) keep links pinned to that commit. `src` is unchanged through `31a9589`, so they still hold.
- Source claims recorded earlier were confirmed at `ef0eced` (redhot `2026-10-04-0345`) and their links stay pinned there.
- Older audit documents keep their historical revision `e0e25e9`.

## Document history

On 2026-10-05 Claude Code revised the whole document set. Codex's design documents (ai-architecture, risk-and-positioning, takedown, ankle-tear, training-and-integration, lua-and-movement, mvp) and `docs/claude/experiment-plan` were merged into these documents. Earlier contents remain in git history up to commit `ebd2650`.
