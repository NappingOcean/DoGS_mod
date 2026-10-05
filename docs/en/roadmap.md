# Roadmap

[한국어](../ko/roadmap.md) · [Contents](index.md)

## Status (2026-10-05)

| Area | Status |
| --- | --- |
| Judgment layer over the engine's pet AI | implemented, [runtime E0–E6] |
| Safety veto: encirclement avoidance, low-HP retreat behind the player, object permanence | implemented, [runtime E2, E3, E5] |
| Return (REGROUP) and engine delegation | implemented, [runtime E3, E5] |
| Control attacks and follow-up (knock down → bite → break off) | implemented, [runtime E2, E6] |
| New Takedown resolution (Lua application, size resistance) | implemented, [runtime E7] (miss detection unverified) |
| Role: Guard (default) | implemented, [runtime E6] |
| Role: Free | implemented, [runtime E0–E5] |
| Per-entity state save/restore | [runtime E4] |
| Firing-line avoidance | decided (approach 2), not implemented |
| Role: Harass (delaying the next enemy) | planned |
| Command device (DoGS whistle) | decided, not implemented |
| Production training, other dog types, hostile NPCs | undecided |

## Next steps

In order; each step moves on only after its experiment meets the success criteria.

1. **E8 Harass probe.** How long does a zombie chase the dog, does it switch to the player as the player gets closer, and is a 2–3 tile holding distance right ([experiments](experiments.md))?
2. **Implement the Harass role.** Picking the next enemy, holding it up after control, and finishing (automatic and recall), built from E8's results ([Harass role](harass.md)).
3. **E9 multiple enemies: Guard versus Harass.** With 3–4 zombies approaching, compare how many enemies are on the player at once, and judge whether encirclement avoidance starts early enough.
4. **Firing-line avoidance: implement and test.** Remember shot trajectories from `on_shoot` and step off them ([behavior design](design.md) section 7). Decide how many turns to remember and how wide to avoid.
5. **Command device (DoGS whistle) and production training.** Build the command whistle that replaces the experimental menu, and a training method ([behavior design](design.md) section 7).
6. **Wider coverage.** Other dog types, hostile NPC perception, compatibility checks with other mods.

The docile stop order (does the dog step away from an adjacent enemy and stop biting when the whistle is blown, `docile_disengage`) is checked in any run of E8 or E9.

## Open questions

- Does miss detection (`dodged`) actually work (no miss occurred in E7)?
- Large enemies get up quickly, so knockdown is worth little against them. Adjust knockdown duration or chance by size?
- Ankle Tear does nothing to enemies with high cut armor (e.g. the zombie moose). Leave it?
- Takedown: are 50% for large targets and 2 turns of knockdown right?
- Ankle Tear: effect stacking and actual application by armor and immunity (not checked in play).
- Do a Guard distance of 3 and an engage distance of 2 hold in other situations (indoors, crowds)?
- Leave the Free role's sawtooth (distance 4↔9) as is?
- Do one-tile steps get stuck among obstacles while enemies are visible (unverified)?
- Do attack cooldown values persist across save and reload (not observed directly in E4)?
- A log flag for "the player stands between the dog and the enemy" during the low-HP retreat, and a "set HP to 35%" menu item (add when needed).

## Decision log

| Date | Decision | Basis |
| --- | --- | --- |
| 2026-10-04 | Drop the implementation that took over the dog's turn; rebuild as a judgment layer over the engine's pet AI | Pre-rebuild play log ([experiments](experiments.md) background) |
| 2026-10-04 | Remove the 3,000 max HP, reach learning and the remote | They invalidated survival experiments or had nothing to do with the philosophy |
| 2026-10-04 | Load modules with the `dogs.` prefix | `lib.*` is BN's shared library; `package.loaded` is shared |
| 2026-10-04 | Keep the low-HP retreat on HP and fall back behind the player | E1: 2 of 3 dogs died; dogs barely regenerate |
| 2026-10-04 | Control follow-up: bite the downed enemy, break off once it stands | E1 |
| 2026-10-05 | Three roles (Guard, Harass, Free); control attacks exist to support the player | User decision |
| 2026-10-05 | Object permanence of 5 turns | E3 retreat oscillation |
| 2026-10-05 | Delegate the return to the engine only with no enemy visible; pause 5 turns when it replaces the destination | E3, E5 |
| 2026-10-05 | Guard: distance 3, normal bites allowed, enemies approaching the dog engaged within distance 3 | User decision |
| 2026-10-05 | Firing-line avoidance by remembering post-shot trajectories (approach 2) | A dog does not know guns but can remember a trajectory (user decision) |
| 2026-10-05 | Delete `mod/` (Codex's implementation); `DoGS_mod/` is the only implementation | The two implementations had diverged too far |
| 2026-10-05 | Guard is the default role | E6: a free-roaming dog runs toward distant enemies and is easily lost |
| 2026-10-05 | Apply Takedown's knockdown from Lua, resisted by size | E6: JSON effects do not apply when armor stops the damage |
| 2026-10-05 | Revise the whole document set | Changes during experiments broke consistency between documents |
| 2026-10-05 | Shelve cutting enemies out of a group by luring (formerly LURE) | Risk of the dog and player being picked off separately; scent tracking brings enemies back anyway (user decision) |
| 2026-10-05 | Harass means controlling the next enemy within 7–8 tiles of the player and holding it up so it chases the dog alone and arrives later | User decision |
| 2026-10-05 | Harass ends both automatically and on recall | User decision |
| 2026-10-05 | The release command device is a command dog whistle (a new item) | The existing whistle is hardcoded; the experimental menu does not suit release (user decision) |
| 2026-10-05 | Respect `docile` (the existing whistle's stop-attacking order), keeping only the safety veto | A command in BN proper (user decision) |
| 2026-10-05 | Replace the crowd experiment (old E8) with a Harass probe (E8) and a multiple-enemy comparison (E9) | Guard and Harass never enter a group by design; how each role performs when several enemies come, and when encirclement avoidance starts, is closer to real play (user decision) |
| 2026-10-05 | A docile dog steps away from an adjacent enemy to complete the stop order | E7: the engine keeps a docile dog biting an adjacent enemy (user decision) |
| 2026-10-05 | Flying enemies: Takedown allowed (struck down), Ankle Tear not (no ankle in reach) | User decision |
| 2026-10-05 | Raise the ankle wound from 10 to 60 turns | A real bite healing in 10 seconds is implausible and shorter than one Harass cycle (user decision) |
| 2026-10-05 | "It survives" includes moving out without hesitation when encirclement looms | User decision |
