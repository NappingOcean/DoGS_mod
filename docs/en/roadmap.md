# Roadmap

[한국어](../ko/roadmap.md) · [Contents](index.md)

## Status (2026-10-05)

| Area | Status |
| --- | --- |
| Judgment layer over the engine's pet AI | implemented, [runtime E0–E6] |
| Safety veto: encirclement avoidance, low-HP retreat behind the player, object permanence | implemented, [runtime E2, E3, E5] |
| Return (REGROUP) and engine delegation | implemented, [runtime E3, E5] |
| Control attacks and follow-up (knock down → bite → break off) | implemented, [runtime E2, E6] |
| New Takedown resolution (Lua application, size resistance) | implemented, not checked in play |
| Role: Guard (default) | implemented, [runtime E6] |
| Role: Free | implemented, [runtime E0–E5] |
| Per-entity state save/restore | [runtime E4] |
| Firing-line avoidance | decided (approach 2), not implemented |
| Role: Harass (lure and straggle) | planned |
| Production training, other dog types, hostile NPCs | undecided |

## Next steps

In order; each step moves on only after its experiment meets the success criteria.

1. **E7 new Takedown resolution check.** Does the fat zombie go down, and does miss detection match the game messages ([experiments](experiments.md))?
2. **E8 crowd (per role).** Compare vanilla, Free and Guard dogs against a group of 5 zombies.
3. **Firing-line avoidance: implement and test.** Remember shot trajectories from `on_shoot` and step off them ([behavior design](design.md) section 7). Decide how many turns to remember and how wide to avoid.
4. **Harass stage 1 (straggling only).** Ankle Tear the outermost or trailing members of an approaching group and break off. Metrics: the time spread of the group's arrival and the maximum number of enemies on the player at once ([Harass role](harass.md)).
5. **Harass stage 2 (lure and separate).** Decide pursuit detection, BREAK_CONTACT, detour return, and the relation to the low-HP retreat during Harass.
6. **Production training and UI.** Currently an experimental menu switch.
7. **Wider coverage.** Other dog types, hostile NPC perception, compatibility checks with other mods.

## Open questions

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
| 2026-10-05 | The Harass role is luring the outermost enemies away, leaving them straggling, and returning (formerly LURE). Ankle Tear serves the straggling | User decision |
| 2026-10-05 | "It survives" includes moving out without hesitation when encirclement looms | User decision |
