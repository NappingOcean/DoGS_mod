# Behavior design

[한국어](../ko/design.md) · [Contents](index.md)

How the dog judges now. Labels: [design] decision, [source] confirmed in BN source, [runtime E#] confirmed in play ([experiments](experiments.md)). Numbers live in [`config.lua`](../../DoGS_mod/dogs/config.lua) and change only through experiments.

## 1. Structure: a judgment layer over the stock pet AI

[design] DoGS does not take over the dog's whole turn. When BN's `lua_ai` callback returns false, the engine's pet AI (target selection, pathfinding, following, normal bites) acts. DoGS returns true and acts itself only when a judgment the engine cannot make is needed. Even when DoGS has nothing to add, the dog does not fall below a vanilla dog.

[runtime E0, E1] The earlier implementation took over every turn, never bit normally, and was weaker than a vanilla dog. That is why it was rebuilt this way.

## 2. Decision order per action

Implementation: `M.turn` in [`ai.lua`](../../DoGS_mod/dogs/ai.lua).

| Step | Condition | Action | Return |
| --- | --- | --- | --- |
| 0 | Other type, untrained, not friendly, restrained/ridden/leashed etc., hallucination | Disable DoGS attacks and leave the action to the engine | false |
| 1 | State RETREAT | Safety veto (section 4) | true / false |
| 1a | `docile` (the existing whistle's stop-attacking order) | Leave everything else to the engine, which picks no target for a docile dog | false |
| 2 | A control attack was just used | While a downed enemy is adjacent, let the engine bite; once it stands, step away (section 5) | false / true |
| 3 | State DEFAULT, exactly one adjacent enemy, at most 2 within 3 tiles | Control attack (section 5) | true |
| 4 | Guard role | Guard behavior (section 6) | true / false |
| 5 | Free role, state REGROUP | Return to the player (section 6) | false / true |
| 6 | Otherwise | Do not intervene | false |

- [design] Step 0 disables DoGS attacks before any other return, so the engine's attack scheduler can never pick them.
- [source] If the callback returns true and position and moves are unchanged, the engine deducts 100 moves, so "wait in place" is simply returning true ([engine notes](engine-notes.md)).

## 3. Perception, states and transitions

**Perception.** [design] Enemies are monsters on the same z-level, within 8 tiles, visible to the dog, and hostile to both the dog and the player. Hostile NPCs are not yet perceived. Each action observes the adjacent enemy count, the count within 3 tiles, the distance to the nearest enemy, the distance to the player and the HP ratio.

**Object permanence.** [design] The last game turn an enemy was perceived is stored as a per-entity value. The low-HP retreat ends only after 5 turns without perceiving an enemy. [runtime E3] Without this rule, the retreat released and re-entered whenever the enemy briefly left sight or the perception radius.

**States.** DEFAULT (the engine leads), RETREAT (safety veto), REGROUP (return to the player). Entry and exit thresholds differ, and each state has a minimum hold (hysteresis).

| State | Enter | Exit | Minimum hold |
| --- | --- | --- | --- |
| RETREAT | 2+ adjacent enemies, or 4+ within 3 tiles, or HP ≤ 40% with an enemy within 5 tiles | 0 adjacent and at most 2 within 3 tiles; at HP ≤ 40%, only after 5 turns without perceiving an enemy | 2 turns |
| REGROUP | More than 8 tiles from the player | 4 tiles or fewer | 3 turns |

[runtime E1, E5] Without minimum holds the state flipped every turn at the boundary. Each transition logs `decide` and shows a game message; messages are on by default and can be turned off in the menu.

## 4. Safety veto

### Encirclement avoidance

[design] In RETREAT above low HP, the dog steps to a tile with a lower risk score: 10 per adjacent enemy, 3 per enemy two tiles away. With risk already 0 it waits in place. With no tile to retreat to, it leaves the fight to the engine.

### Low-HP retreat: behind the player

[design] At HP ≤ 40% with an enemy within 5 tiles, the dog leaves the fight.

- The dog moves only through tiles not adjacent to any enemy to a point **behind the player**: two tiles past the player, away from the enemy nearest the dog. It is recomputed every action.
- On arrival it waits (`hold`). The pursuer meets the player, and ending the situation is the player's job.
- If blocked with an enemy adjacent, the dog leaves the fight to the engine.

[source] Flesh monsters such as dogs regenerate only 0.25 HP per hour, so the low-HP retreat effectively takes the dog out of the fight.

[runtime E2, E3, E5] In all 6 low-HP retreats, the dog took no further damage after entry, waited within 2 tiles of the player, and released once the player killed the enemy. [runtime E1] Before this rule, the retreat ended whenever no enemy was adjacent, so the dog re-engaged, got hit, and died.

This brings the enemy to the player; it is a deliberate choice for wounded dogs only.

## 5. Control attacks and follow-up

Numbers and resolution: [control attacks](attacks.md).

- **Opportunity.** [design] Used when the state is DEFAULT, exactly one enemy is adjacent, and at most 2 enemies are within 3 tiles.
- **Follow-up.** [design] After a control attack, while a downed enemy is adjacent the engine bites it; once it stands, the dog steps away: "knock down → bite → break off once it stands." [runtime E1, E2] Breaking off right after the attack threw away the chance to bite a downed enemy (dodge 0). After the change, several runs had the dog kill a zombie without taking damage.

## 6. Roles

[design] The player sets each dog's role (Role in the menu); the dog judges within it. The default is **Guard**; Free must be chosen in the menu. Survival (RETREAT) takes priority in every role.

| Role | Status | Scope of the dog's judgment |
| --- | --- | --- |
| Guard | implemented, [runtime E6] | Keeps within 3 tiles of the player; takes on only enemies approaching the player or the dog |
| Harass | planned | While the player is engaged, controls the next enemy within 7–8 tiles and holds it up, leading it to chase the dog alone so it arrives later ([Harass role](harass.md)) |
| Free | implemented, [runtime E0–E5] | Mixes control attacks into the engine's fighting; only the 8-tile leash applies |

### Guard

- Farther than 3 tiles from the player, return (same method as "Return" below).
- With an enemy adjacent, let the engine bite; the enemy in front is removed quickly.
- With an enemy within 2 tiles of the player or the dog, approach the one closest to the player, never stepping onto a tile more than 3 tiles from the player (`step kind=intercept`).
- Otherwise wait in place. Distant enemies are ignored, so the engine never chases them.

[runtime E6] Fighting 5 regular zombies alongside the player, the player took 2 hits with the Guard dog against 5 with a vanilla dog. The Guard dog stayed within 3 tiles of the player.

### Free and return

- In REGROUP the dog returns to the player.
- [source, runtime E3] The engine follows a DoGS-set destination only while it has no target; with a target it replaces the destination.
- [design] So the dog delegates the return to the engine's pathfinding only when no hostile monster is visible at any range and the engine has not replaced a destination in the last 5 turns. Otherwise DoGS steps one tile at a time. When the engine is seen replacing the destination (`probe_result`), delegation stops for 5 turns.
- [runtime E5] Delegating on the 8-tile perception alone let the engine chase a farther zombie, and the dog ended up 60 tiles away. After the fix, all 48 returns finished in 4–24 turns.
- [runtime E5] In the Free role the engine moves the dog toward distant targets during DEFAULT, leaving a sawtooth between distances 4 and 9. The Guard role prevents this.

## 7. Planned behavior

### Firing-line avoidance (approach 2 chosen, not implemented)

- [source] Projectiles skip friendly creatures only within 1 tile of the shooter; a dog farther along the line can be hit. A dog adjacent to the player cannot.
- [source] Aiming and firing finish within one player action, and the player's target is not readable from Lua, so the dog cannot react to aiming.
- [design] Use the `on_shoot` hook to receive the shooter and aim position right after a shot, remember that trajectory for a few turns, and step off its axis. Do not avoid by reading the weapon in advance: the dog does not know what a gun is, but it can remember a trajectory after a shot. If the player then shoots another target, the dog may be in the way; this is accepted as a dog's limitation.
- To decide at implementation: how many turns to remember, and how many tiles either side of the trajectory to avoid (shot spread, dispersion).

### Command device: the DoGS whistle (decided, not implemented)

[design, 2026-10-05] Training and roles are set from an experimental action-menu entry for now. The release version uses a **command dog whistle** instead.

- A new item, separate from the existing dog whistle. Its description says a tongue-stopped hole cut into the mouthpiece lets it produce more kinds of signals than the ordinary whistle.
- Candidate signals: role orders (Guard, Harass, Free) and recalling a harassing dog. The exact list is undecided.
- Being a signal the dog can actually hear, it fits the principle that the dog judges only by what it can perceive.

**Findings about the existing whistle.**

- [source] The existing whistles (`dog_whistle`, `dog_whistle_wood`) use the hardcoded C++ `DOG_WHISTLE` action. It toggles the `docile` effect on every friendly dog (`DOGFOOD` or `DOG_WHISTLE` flag): docile dogs follow closely and stop attacking; otherwise they resume attacking. It applies to all such dogs on the current map, with no distance or sound check ([iuse.cpp:4314](https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/iuse.cpp#L4314)).
- [runtime] Registering an item-use function from Lua (`game.iuse_functions`) worked for the earlier implementation's remote item.
- [design, 2026-10-05] DoGS respects `docile`. While docile, it keeps only the safety veto (step 1) and leaves the rest to the engine (decision step 1a). The docile behavior itself is not especially graceful, but it is a command in BN proper, so it is followed. Not checked in play.

**To decide:** the signal list, audible range (the whole map like the existing whistle, or a distance limit), how to obtain it (recipe, spawn locations), and how it relates to production training.

### Harass role

The flow, the difference from Guard, open points, and the shelved "cut enemies out of a group" idea are in [Harass role](harass.md).

## 8. Known limits

- Hostile NPCs are not perceived.
- Only `mon_dog` (Labrador mutt) is covered.
- While enemies are visible, movement is DoGS's one-tile step without pathfinding. Whether it gets stuck among obstacles is untested.
- The engine's target choice and attack target cannot be changed from Lua; to take on a specific enemy, the dog must move next to it itself.
- Off-sight targets (scent or sound tracking) cannot be detected; a replaced destination is used as the signal.
