# Roadmap

[한국어](../ko/roadmap.md) · [Contents](index.md)

## Status (2026-10-17)

| Area | Status |
| --- | --- |
| Judgment layer over the engine's pet AI | implemented, [runtime E0–E7] |
| Safety veto: encirclement avoidance, low-HP retreat behind the player, object permanence | implemented, [runtime E2, E3, E5] |
| Return (REGROUP) and engine delegation | implemented, [runtime E3, E5] |
| Control attacks and follow-up (knock down → bite → break off) | implemented, [runtime E2, E6] |
| Takedown resolution (Lua application) | implemented, [runtime E7] (miss detection unverified). Size resistance replaced by weight ratio and training level (2026-10-17, not checked in play) |
| Role: Guard (default) | implemented, [runtime E6] |
| Role: Free | implemented, [runtime E0–E5] |
| Per-entity state save/restore | [runtime E4] |
| Firing-line avoidance | decided (approach 2), not implemented |
| Role: Harass (delaying the next enemy) | v0 implemented, not checked in play. In v0.1 only selectable in debug mode |
| Command device (DoGS whistle) | implemented (role orders), not checked in play |
| Fetch (bring back registered items) | design candidate, not implemented |
| Acquisition and training: capabilities open at fixed BN training levels | implemented, not checked in play. Details (starting-profession dogs, bond) undecided |
| Other dog types | applied to 12 adult breeds, not checked in play |
| Debug mode (logs, state messages, experiment tools) | implemented, not checked in play |
| Hostile NPCs | undecided |

## v0.1 release

The release scope is separate from the experiment steps (decided 2026-10-17). v0.1 holds the behavior confirmed in play (judgment layer, safety veto, return, control attacks and follow-up, Guard and Free roles, state saving) and what a release needs (training levels, whistle, breeds, debug mode). Harass is selectable only in debug mode.

- [x] Open capabilities by BN training level; the experimental `dogs_trained` and laboratory menu are gone
- [x] Hide Harass (debug mode only)
- [x] Debug mode: logs, state messages, experiment tools
- [x] Apply to 12 adult breeds
- [x] Command whistle (role orders)
- [x] E10 v0.1 check play ([experiments](experiments.md)); confirmed on redhot `2026-10-16-0238` (`f9586ef`)
- [ ] Release zip and install instructions
- [ ] README from the player's side: what differs from vanilla dogs, supported build, known limits
- [x] Drop "(rebuild)" from the mod name and "Experimental" from its description

## After v0.1

In order; each step moves on only after its experiment meets the success criteria.

1. **E8 Harass v0 probe (rerun).** Does the Harass dog hold its target up, and how long does a zombie chase a dog that keeps its distance? Read from `track`, whose `chases` field shows the zombie's actual target since 8e8aa90 ([experiments](experiments.md)).
2. **Refine Harass.** Adjust the holding distance, range and finishing from E8 ([Harass role](harass.md)).
3. **E9 multiple enemies: Guard versus Harass.** With 3–4 zombies approaching, compare how many enemies are on the player at once, and judge whether encirclement avoidance starts early enough (it looked late in E8's first attempt).
4. **Firing-line avoidance: implement and test.** Remember shot trajectories from `on_shoot` and step off them ([behavior design](design.md) section 7). Decide how many turns to remember and how wide to avoid.
5. **More whistle signals and the remaining acquisition/training decisions.** Harass order and recall signals, audible range, starting-profession dogs, bond ([behavior design](design.md) section 7).
6. **Fetch.** On a whistle command, bring back registered items into the bag ([behavior design](design.md) section 7).
7. **Wider coverage.** Hostile NPC perception, compatibility checks with other mods.

The docile stop order was checked once in E8's first attempt; check it again in E8 and E9 runs.

## Open questions

- Does miss detection (`dodged`) actually work (no miss occurred in E7)?
- Ankle Tear does nothing to enemies with high cut armor (e.g. the zombie moose). Leave it?
- Are the Takedown weight-ratio values (attempt 0.3, 100% at 0.6, floor 50%, +5% per training level, 2–4 turns downed) right (not checked in play)?
- Ankle Tear: effect stacking and actual application by armor and immunity (not checked in play).
- Do a Guard distance of 3 and an engage distance of 2 hold in other situations (indoors, crowds)?
- Leave the Free role's sawtooth (distance 4↔9) as is?
- Do one-tile steps get stuck among obstacles while enemies are visible (unverified)?
- Do attack cooldown values persist across save and reload (not observed directly in E4)?
- Acquisition and training: whether starting-profession dogs (e.g. the K9 German shepherd) begin trained, what happens when the handler changes or the dog is neglected, and whether to use the bond (`pet_bond_level`) as a basis for judgment ([behavior design](design.md) section 7).
- Weigh tile danger by enemy melee damage (`melee_dice`, `melee_damage` on the monster type, readable since 8e8aa90) instead of counting enemies equally?
- Fetch: radius, how the capability is granted (relation to training), the registration UI, reading the bag volume from Lua.
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
| 2026-10-05 | Implement Harass v0 first and run E8 as a v0 probe | The Free role cannot yield valid Harass-probe data (E8 first attempt, user decision) |
| 2026-10-05 | Replace the crowd experiment (old E8) with a Harass probe (E8) and a multiple-enemy comparison (E9) | Guard and Harass never enter a group by design; how each role performs when several enemies come, and when encirclement avoidance starts, is closer to real play (user decision) |
| 2026-10-05 | A docile dog steps away from an adjacent enemy to complete the stop order | E7: the engine keeps a docile dog biting an adjacent enemy (user decision) |
| 2026-10-05 | Flying enemies: Takedown allowed (struck down), Ankle Tear not (no ankle in reach) | User decision |
| 2026-10-05 | Raise the ankle wound from 10 to 60 turns | A real bite healing in 10 seconds is implausible and shorter than one Harass cycle (user decision) |
| 2026-10-05 | "It survives" includes moving out without hesitation when encirclement looms | User decision |
| 2026-10-06 | Use the 8e8aa90 monster bindings: `attack_target` in `track`/`probe_result` logs, `movement_impaired` in the restraint check, `is_dead_or_dying` for Takedown | BN #10504; E8 needs whom the zombie chases ([engine notes](engine-notes.md)) |
| 2026-10-08 | Keep Fetch as a design candidate: on a whistle command, bring back registered items from nearby | Trained-dog behavior, practical for bow and javelin users (user decision) |
| 2026-10-08 | Store the fetch capability as an entity value, not the monster flag `CAN_FETCH` | An unused stock flag could collide if BN implements it later (user decision) |
| 2026-10-08 | Only a dog wearing a vanilla pet bag fetches | The bag is the only place the player can take fetched items from with the vanilla menu; it also gives a reason to make a pet bag (user decision) |
| 2026-10-08 | Fetch targets: up to 3 types chosen from the player's items; with none registered, only a message; no fetching of whatever was shot or thrown | Chasing far projectiles brings too many unknowns (user decision) |
| 2026-10-08 | Move the reference revision to `31a9589` (redhot `2026-10-07-0423`) | The installed game is this build; no `src` changes since `8e8aa90`. Move again when a BN PR relevant to DoGS lands |
| 2026-10-09 | Move the reference revision to `a27f19d` (redhot `2026-10-09-0454`) | The installed experimental build is this one |
| 2026-10-09 | Design how a dog becomes a DoGS dog (taming, bonding, training), not only how it behaves | User decision |
| 2026-10-09 | DoGS capabilities open at fixed BN `training_level` values (1: Guard, Free and safety veto; 2: control attacks; 3: Harass and Fetch), not at a fraction of the max level | Breed differences become differences in judgment. Small breeds (max 2) never take Harass, so stats never fail to back the judgment (user decision) |
| 2026-10-09 | Keep BN's per-level training stat gains; DoGS does not override `pet_training` | BN intends them and DoGS has no right to revert them. Judgment-first forbids covering poor judgment with stats, not stat gains; untrained dogs die to the stat gap before judgment matters (user decision) |
| 2026-10-17 | Takedown is tried only at a dog/target weight ratio of 0.3 or more; chance and knockdown duration follow the ratio and BN training level. Replaces the chance by size | Trying only on targets it can bring down is the judgment; no small-breed exception is needed. Training level is the knack of striking the center of mass (user decision) |
| 2026-10-17 | Takedown judgment does not model misjudging by volume (apparent size) | It is a trained move; in BN data weight and volume are mostly proportional and breed volumes are mostly inherited (user decision) |
| 2026-10-17 | Separate the v0.1 release scope from the experiment steps. It holds behavior confirmed in play and what a release needs; the steps from E8 on move after v0.1 | Waiting for every step keeps pushing the release back (user decision) |
| 2026-10-17 | Hide Harass in v0.1; selectable only in debug mode | A role not checked in play should not spoil the first impression (user decision) |
| 2026-10-17 | Ship the command whistle in v0.1; its only signals are role orders (Guard, Free) | Copying the wooden whistle and its recipe and adding a Lua use function is enough; the signal list and range wait (user decision) |
| 2026-10-17 | Apply DoGS to 12 adult breeds; puppies are excluded and join when grown | The judgment logic does not depend on breed, and the weight-ratio Takedown needs no small-breed exception (user decision) |
| 2026-10-17 | Add a debug mode, toggled from the action menu's Debug category; on, it opens logs, state messages and experiment tools. Off by default | Keeps a release's log file and messages quiet while keeping the experiment tools (user decision) |
| 2026-10-17 | Retire the experimental `dogs_trained`; capabilities open by BN `training_level`. A level override exists only in debug mode | Implements the 2026-10-09 decision; the override allows per-level experiments without training time |
| 2026-10-17 | Give dogs at level 1 or more the permanent, visible effect `[DoGS] Trained dog`, which blocks the stock hit-and-run (`run`) | Guard moved the dog in and the fleeing engine pulled it out again, in a loop (E10-A, B). Deleting the flag would also change level-0 and wild dogs, so it is not used (user decision) |
| 2026-10-17 | Move the reference revision to `f9586ef` (redhot `2026-10-16-0238`) | The installed experimental build is this one; cited sources changed, but no claim DoGS relies on |
