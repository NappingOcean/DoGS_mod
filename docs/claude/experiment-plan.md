# DoGS Rebuild Experiment Plan

[한국어](experiment-plan.ko.md)

> **Written by Claude Code (Claude Opus 5.5), 2026-10-04.**
> Documents in this directory (`docs/claude/`) are written by Claude Code and are separate from the existing documents in `docs/en` and `docs/ko` (written by Codex). The design philosophy follows [01 Goals and Design Philosophy](../en/philosophy.md) and is not repeated here. This document covers only **what will change and how it will be verified**.

Basis: executable redhot 2026-10-04-0345 (`ef0eced`); source checks against a local BN checkout at `e569e75`. The pre-rebuild code is commit `1c1ac60`.

## 1. Starting point

Observed in an actual play log of the pre-rebuild code (2026-10-04 22:03–22:06, state before commit `9316c3e`):

- The dog never attacked except with special attacks. It stood next to a zombie, used Takedown (2 damage) every 8 turns, and took 6–7 damage roughly every 5 turns. Its combat contribution is below a vanilla dog.
- The later fix that backs off during cooldown (COOL_OFF) reduces damage contribution further and abandons protecting the player.
- At the leash boundary, REGROUP and SKIRMISH alternated every turn (22:06:15–19). There is no hysteresis.
- The custom one-tile movement has no pathfinding and repeatedly logged `move_blocked` (21:46).
- A base max HP of 3,000 effectively never triggers the 50% retreat threshold, which invalidates survival-judgment experiments.

## 2. Approach: a judgment layer on top of the engine AI

DoGS does not replace the dog's whole turn. **By default it returns `false` and the engine's pet AI** (target selection, pathfinding, following, normal bites) acts. DoGS intercepts only when a judgment the engine cannot make is needed.

Then even when DoGS judges wrongly or has nothing to say, the dog does not fall below vanilla, and improvement can be measured against vanilla.

### Per-action decision order

| Order | Condition | DoGS action | Return |
| --- | --- | --- | --- |
| 0 | Untrained, not friendly, movement-restrained, ridden, leashed, etc. | Disable DoGS attacks | false |
| 1 | **Safety veto**: imminent encirclement, or low HP with an enemy within 5 tiles | Encirclement: one risk-reducing retreat step. Low HP: move through tiles not adjacent to enemies to behind the player, then wait. If impossible with an enemy adjacent, defer to the engine | true / false |
| 2 | **Control follow-up**: after a control attack | While an adjacent enemy is downed, let the engine bite; once it stands, step away | false / true |
| 3 | **Control opportunity**: adjacent to one exposed enemy, attack ready, safe | Takedown / Ankle Tear | true |
| 4 | **Guard role** | Acts per "Guard role specification" instead of step 5 | true / false |
| 5 | **Leash** (Free role): in REGROUP | If no hostile monster is visible at any range and the engine has not replaced a destination in the last 5 turns, set the player as the destination and leave pathing to the engine. Otherwise DoGS steps one tile at a time (E3, E5) | false / true |
| 6 | Otherwise | Do not intervene | false |

- Step 2 is "knock down → bite → break off once it stands". E1 showed that disengaging right after Takedown throws away the chance to bite a downed enemy (dodge 0), so it was changed.
- Low HP with no visible enemy: do not intervene; leave following to the engine.

### Roles (Free and Guard implemented, Harass not yet)

The player assigns a role to each dog (Role item in the action menu; Free by default). The role sets the intent (what to do); the dog judges how and when. Mission orders against groups (LURE etc.) come later as one-off commands. Survival (RETREAT) takes priority in every role.

| Role | Scope of the dog's judgment | Experiment metric |
| --- | --- | --- |
| Guard | Stays within 2–3 tiles of the player. Engages only enemies on or approaching the player. Uses Takedown to create openings for the player | Damage taken by the player, player's time to kill |
| Harass | Holds off enemies not engaged with the player. Slows them with Ankle Tear, hits and runs | Enemies reaching the player |
| Free | Current behavior: control attacks mixed into stock engagement | E0/E1 metrics |

Control attacks exist to support the player's attacks and disrupt other enemies, not to let the dog kill alone. E0/E1, where the player does not attack, are therefore read only as solo survival tests of the Free role. ASSIST and INTERCEPT in the earlier design were tactics the dog chose; with the Guard role the player chooses.

### Guard role specification (implemented)

- **Distance:** stay within 3 tiles of the player. While an enemy is visible, DoGS moves the dog itself (E3).
- **Enemies to engage:** enemies on the player or within 2 tiles of the player. Enemies approaching the dog itself are engaged as long as the dog stays within 3 tiles of the player.
- **Attacks:** both control attacks and the engine's normal bites are allowed; with an enemy right there, quick removal matters. A knocked-down enemy is also open to the player.
- **Other enemies:** ignored; the dog stays by the player. The round trips seen in E5, where the engine chased distant targets, should not occur in the Guard role.
- **Survival:** the low-HP retreat and encirclement avoidance take priority.

Implementation (decision step 4): farther than 3 tiles from the player, return (same method as the Free role's regroup). With an enemy adjacent, let the engine bite. With a threat (the enemy closest to the player among those within 2 tiles of the player or the dog), approach only through tiles within 3 tiles of the player (`step kind=intercept`). Otherwise wait in place. Control attacks and the control follow-up are the same as in the Free role.

### Firing-line avoidance (approach 2 chosen, not implemented)

Explored whether the dog can keep out of the line of fire when the player holds a gun. Basis: `ef0eced`.

- **Need (source-confirmed):** projectiles skip friendly creatures only within 1 tile of the shooter (projectile_attack in `src/ballistics.cpp`). A friendly dog farther along the line gets an unintentional-hit roll. A dog adjacent to the player cannot be hit.
- **Reacting to the moment of aiming is impossible.** Aiming and firing finish within one player action, and monsters do not act in between. The player's last target (`Character::last_target`) is not exposed to Lua either.
- **Possible approach 1, prevention:** when the player wields a gun (scan `all_items`, check `is_wielding` and `is_gun`), avoid tiles on the lines from the player to visible enemies, plus one tile either side. Tiles within 1 tile of the player or behind the player are safe. This fits into the Guard role's positioning as one condition.
- **Possible approach 2, reaction:** the `on_shoot` hook reports the shooter and aim position right after firing. Remember recent firing directions for a few turns and step off that axis, against follow-up shots in a burst.
- **Limits:** the player may shoot an enemy the dog cannot see, or another target. Whether one tile either side covers shot spread and dispersion needs testing. The inventory scan can be computed once per game turn and reused.
- **Decision:** implement approach 2 (reaction). A dog does not really know what a gun or bow is, but after a shot it can remember that things fly along that path. So approach 1, which reads the weapon in advance, is not used. If the player then shoots another target, the dog may be in the way; the player can be expected to accept this as a dog's limitation. To be implemented after the Guard role.

### End state of the low-HP retreat

The dog's HP effectively does not recover: natural regeneration for flesh monsters is 0.25 HP per hour (`src/monster.cpp`, `ef0eced`). A low-HP retreat therefore takes the dog out of the fight. The dog survives; the player ends the situation.

- The dog moves through tiles not adjacent to any enemy to a point **behind the player**: two tiles past the player, away from the enemy nearest the dog. It waits there.
- The pursuer meets the player. The retreat ends after 5 turns without perceiving an enemy (object permanence: an enemy that leaves sight or the perception radius is remembered briefly).
- This brings the enemy to the player, against LURE's rule of not dragging enemies to the player. It is a deliberate choice for wounded dogs only.
- Shaking off the pursuer (BREAK_CONTACT) is handled with LURE.

### Hysteresis

Entry and exit thresholds are separate, with a minimum hold time. Initial values below are tuned from results.

| State | Enter | Exit | Minimum hold |
| --- | --- | --- | --- |
| REGROUP | More than 8 tiles from the player | 4 tiles or fewer | 3 turns |
| RETREAT (veto) | 2+ adjacent enemies, or 4+ enemies within 3 tiles, or HP ≤ 40% with an enemy within 5 tiles | 0 adjacent and 2 or fewer within 3 tiles; at HP ≤ 40%, only after 5 turns without perceiving an enemy | 2 turns |

### Cooldowns

Do not rely on engine attack cooldowns. After use, store the `next usable game turn` in a per-entity value. Enable the attack and set its cooldown to 0 only at the moment of use, execute, then disable it immediately. Remove the elapsed-turn compensation code.

## 3. Code layout

Paths are relative to the repository (DoGS_mod) root. The rebuild is written fresh in [`DoGS_mod/`](../../DoGS_mod/). Codex's earlier `mod/` and its documents (`docs/*/mvp.md`) were deleted after E5 and remain in commit `1c1ac60`. The game's `mods/DoGS` junction points to `DoGS_mod/` through [`scripts/Install-Mod.ps1`](../../scripts/Install-Mod.ps1).

Modules live under `dogs/` and are loaded as `require("dogs.ai")`. At the executable's revision the loader (`src/catalua_loader.cpp`) maps `lib.*` to `data/lua/lib/`, and `package.loaded` is shared by all mods, so a mod-specific prefix is required.

| File | Role |
| --- | --- |
| [`DoGS_mod/preload.lua`](../../DoGS_mod/preload.lua) | Loads modules; registers the AI callback, hook, menu and periodic log; runs policy checks |
| [`DoGS_mod/finalize.lua`](../../DoGS_mod/finalize.lua) | Validates the dog type and effect IDs |
| [`DoGS_mod/json/dogs.json`](../../DoGS_mod/json/dogs.json) | mon_dog override: adds the two attacks only; HP stays vanilla |
| [`DoGS_mod/dogs/ai.lua`](../../DoGS_mod/dogs/ai.lua) | Decision order from section 2 |
| [`DoGS_mod/dogs/policy.lua`](../../DoGS_mod/dogs/policy.lua) | Pure functions: state transitions (hysteresis), control window, attack choice, step ranking |
| [`DoGS_mod/dogs/perception.lua`](../../DoGS_mod/dogs/perception.lua) | Enemy scan and observations |
| [`DoGS_mod/dogs/movement.lua`](../../DoGS_mod/dogs/movement.lua) | One-tile retreat, disengage and regroup steps |
| [`DoGS_mod/dogs/attacks.lua`](../../DoGS_mod/dogs/attacks.lua) | Value-based cooldowns and attack execution |
| [`DoGS_mod/dogs/events.lua`](../../DoGS_mod/dogs/events.lua) | 10-turn summaries and normal melee records, untrained dogs included (E0) |
| [`DoGS_mod/dogs/menu.lua`](../../DoGS_mod/dogs/menu.lua) | action_menu: training, attack mode, state messages (on by default), HP refill, role (Free/Guard) |
| [`DoGS_mod/dogs/tests.lua`](../../DoGS_mod/dogs/tests.lua) | Policy-function checks; not evidence of engine behavior |

Not carried over from the Codex implementation: 3,000 HP, reach learning, the remote item, per-turn state dumps, engine cooldown compensation. `heavysnare` and `lightsnare` were removed from the restraint list: monster.cpp references them, but they have no JSON definition at `ef0eced`, and the finalize check failed on them.

### Existing saves

- The mod ID is unchanged, so existing test worlds still load.
- Existing dogs return to vanilla max HP; use **Refill HP** in the menu.
- The old remote item (`dogs_debug_remote`) is no longer defined; if a save contains one, BN treats it as an unknown item.
- Old per-entity values (`dogs_action` etc.) remain but are not read.

## 4. Experiments

Numbers are the order of execution. E0 and E1 are done (section 6); the rest follow from E2 in this order. E6 and E7 come after the roles are implemented.

Common conditions: a separate test world, open terrain, daytime, at least 3 runs per experiment. Player attacks and HP healing are set per experiment.

| Experiment | Player attacks | HP healing |
| --- | --- | --- |
| E0, E1 | None | Between runs only |
| E2 | Kills the zombie once the dog is behind the player | Between runs only |
| E3, E4, E5 | For cleanup if needed | Allowed mid-run |
| E6 | Fights alongside | Between runs only |
| E7 | Kills only zombies adjacent to the player | Between runs only |

### E0 Baseline — vanilla dog (done)
- Setup: a tamed Labrador mutt; one regular zombie spawned 5 tiles away.
- Measure: turns until the zombie dies, damage taken by the dog, maximum distance from the player.
- Purpose: the baseline for solo tests of the Free role.

### E1 Solo control cycle (done)
- Setup: as E0, DoGS training ON, attack mode auto.
- Check: does the control attack → disengage → engine engagement cycle actually occur? Are normal bites mixed in?
- Success: turns until the zombie dies ≤ E0, and damage taken by the dog < E0.
- Reading: with no player attacks, this is only a solo survival test of the Free role. Not rerun; the revised control follow-up is observed in E2.

### E2 Low-HP retreat (done)
- Setup: a DoGS dog (Free role) and one regular zombie. The player stands still about 4 tiles from them. When the wounded dog falls back behind the player, the player kills the zombie.
- Success:
  - After entering the retreat, the dog takes no damage unless cornered (checked with `melee` and `summary`).
  - Within 10 turns of entry, the dog is within 2 tiles of the player, on the side away from the zombie.
  - The retreat ends once the zombie is killed (`decide`).
- Failure: hit while not cornered, moving away from the player, or repeated retreat entry/exit.
- Also observe: before the dog is wounded, does "knock down → bite → break off once it stands" occur (`special` followed by `melee`, then `disengage`)?

### E3 Engine delegation probe (done)
The engine's `plan()` recomputes target and destination on every action. Check:
- With the probe enabled in the menu, REGROUP calls `set_move_target` and returns false. `kept` in `probe_result` shows whether the engine keeps or overwrites that destination. (After the experiment the probe menu item was removed; delegation without enemies became the default.)
- The result decides how the Guard role moves: delegate to the engine if kept; if overwritten, DoGS moves directly only in those situations.
- Roles are not implemented before this result.

### E4 State persistence (done)
- Are DoGS attacks disabled on an untrained dog's first action?
- After save and reload, do training state, cooldown values, disabled attacks and entity numbers persist?
- Can be done during another experiment's run by saving and reloading.

### E5 Leash and oscillation (done: first run failed, second passed)
- Setup: the player walks away from a zombie group.
- Check: REGROUP entry/exit frequency.
- Success: no round trip between the same two states shorter than the minimum hold.
- The result also informs the Guard role's distance limits.

### (Role implementation)

Implement the Guard, Harass and Free roles based on E3. Guard is implemented; Harass comes later.

### E6 Guard
- Setup: two regular zombies, apart from each other, about 6 tiles from the player. The player fights them with a melee weapon. Repeat with a vanilla dog and a Guard-role dog.
- Measure: damage taken by the player, turns until the player has killed both zombies, turns the dog spent more than 3 tiles from the player (`player` in `summary`).
- Check: does the dog close on zombies approaching the player (`step kind=intercept`)? Does it avoid chasing distant zombies while guarding? Do control attacks turn into openings for the player?
- Success: the player takes less damage than with the vanilla dog, and the dog stays within 3 tiles of the player except while returning.

### E7 Crowd (per role)
- Setup: a group of 5 regular zombies 6 tiles away. Repeat the same setup with a vanilla dog, a Free-role dog and a Guard-role dog.
- The player kills only zombies adjacent to the player; the verdict covers the dog's behavior up to then.
- Check: does the dog avoid the crowd center? Does the veto keep the dog from staying adjacent to 2+ enemies for more than one turn? Does the wounded dog fall back behind the player?
- Success: the dog survives, and cumulative turns adjacent to 2+ enemies are fewer than the vanilla dog. For the Guard role, also compare damage taken by the player.

## 5. Logging

`[DoGS]` lines in `config/debug.log`. Record decision events instead of per-turn state dumps.

| Event | Content |
| --- | --- |
| `decide` | State transition (before→after) and basis: HP ratio, adjacent count, count within 3 tiles, player distance |
| `step` / `step_failed` | One-tile retreat, flee, disengage, regroup or intercept (Guard) result, with risk score before/after |
| `hold` | Start of a wait during the low-HP retreat (e.g. behind the player); once per wait |
| `disengage` | Whether the dog tried to break off on the action after a control attack |
| `special` | Attack ID, target ID and type, actual HP damage, downed/bleed/ankle flags |
| `melee` | The dog's normal attacks seen through the engine's normal melee hook: target type, hit roll, target HP after the attack |
| `summary` | Every 10 turns for every friendly Labrador mutt: trained flag, role, state, position, HP, player distance, nearby enemy count and HP sum |
| `probe_result` | Logged only when the engine replaced a delegated REGROUP destination: the destination set and the replacement (absolute coordinates), player distance before/after. Once logged, delegation stops for 5 turns. During E3, `probe` and `kept=true` were logged too |
| `death` | Deaths of dogs, monsters killed by dogs, and monsters DoGS has numbered (attack targets): victim and killer (monster type and number, `avatar`, or `none`) |
| `menu` | Menu changes |

Every line written during play carries the game turn (`turn=`) and an entity number (`dog=`). The entity number is stored as a per-entity value and should survive save/load (checked in E4).

Experiment verdicts are drawn from analysis of this log and recorded in section 6.

## 6. Results

### 2026-10-04 E0 and E1 (3 runs each)

Log: `config/debug.log` in the game user directory, 23:14–23:30. Executable `ef0eced`, rebuild code (uncommitted). No mid-run healing (no `menu choice=5`). After each run the experimenter killed the surviving dog and zombie. Dog deaths come from the experimenter's direct observation, not the log (marked † below). Engagement time is game turns from first contact until zombie HP reaches 0 or below.

| Run | Dog | Engagement | Damage taken | Outcome |
| --- | --- | --- | --- | --- |
| E0-1 | #1 | 10 turns | 20 | Zombie killed |
| E0-2 | #2 | 7 turns | 16 | Zombie killed |
| E0-3 | #3 | — | 30 (died) | Dog died with zombie at 59 HP† |
| E1-1 | #4 | — | 30 (died) | Dog died with zombie at 52 HP† |
| E1-2 | #6 | 22 turns | 12 | Zombie killed |
| E1-3 | #8 | — | 30 (died) | Dog died with zombie at 12 HP† |

**Verdict: E1 failed.** Dogs died in 1 of 3 E0 runs and 2 of 3 E1 runs. In runs where the dog killed the zombie, E1 also took longer (22 turns) than E0 (7–10 turns). Deaths are confirmed only by the experimenter's observation; the log has no death event and cannot separate them from cleanup kills.

Observations:

1. **Low-HP retreat oscillation.** #4 and #8, at or below 40% HP, cycled roughly every 3 turns: enter RETREAT → step back 2–3 tiles → return to DEFAULT once no enemy is adjacent → engine re-approaches → takes a hit → RETREAT. HP fell 0.40→0.20 and 0.33→0.17→0.03 meanwhile. The exit condition ignores HP; this is a design flaw. The dog (speed 150) is faster than the zombie (70) yet never got away.
2. **Control attacks reduce damage contribution.** A special attack deals 2–4 damage; a stock bite deals 5–10. Disengaging right after Takedown throws away the window when the zombie is downed (dodge 0). #4 attempted only one stock bite during the whole engagement (missed).
3. **Regroup/engagement round trips.** #4 cycled DEFAULT↔REGROUP four times with a 5–7 turn period: the engine chases a zombie more than 8 tiles from the player and DoGS drags the dog back. Each state's minimum hold was respected, but the same round trip appeared at a longer period.
4. **Coordinates.** `get_pos_ms` is reality-bubble local and shifts when the map shifts (#4 appears to move 11 tiles in one turn). This is harmless within one decision, but the probe destination stored across turns (now E3) needs `abs_pos`.

The stock melee hook (`melee`) and special-attack records (`special`) worked as intended. The hook makes stock bite damage measurable.

### 2026-10-05 E2 (low-HP retreat)

Log: `config/debug.log` 23:59–00:06. One dog, #10, fought 7 zombies (#11–#17) in turn. HP was refilled from the menu between runs (`menu choice=5`). The player killed a zombie only after the dog had fallen back.

| Run | Zombie | Low-HP retreat | Outcome | Killer (`death`) |
| --- | --- | --- | --- | --- |
| 1 | #11 | Entered (HP 0.17) | Within 1 tile of the player after 4 turns. HP held at 5 afterwards (no further damage). Released after the zombie died | avatar |
| 2 | #12 | No | Dog killed it in 10 turns. Dog HP stayed 30 | mon_dog#10 |
| 3 | #13 | No | Zombie died at 1 HP while bleeding. One REGROUP during the run | none |
| 4 | #14 | No | Dog killed it in 10 turns | mon_dog#10 |
| 5 | #15 | No | Dog killed it in 13 turns | mon_dog#10 |
| 6 | #16 | Entered (HP 0.30) | Within 2 tiles of the player after about 6 turns. HP held at 9 afterwards. Released after the zombie died | avatar |
| 7 | #17 | No | Dog killed it in 12 turns. Dog HP stayed 30 | mon_dog#10 |

**Verdict: E2 passed.** Both observed low-HP retreats met the success criteria: no further damage after entry, within 2 tiles of the player inside 10 turns, and the retreat ended after the zombie died. Only 2 runs produced a retreat, fewer than the planned 3; the experimenter judged this sufficient. The "side away from the zombie" condition could not be checked because the log has no zombie position.

Observations:

1. **The control follow-up worked.** After Takedown the engine bit the downed zombie repeatedly (`special` → several `melee`), and the dog broke off once it stood (`disengage`). In 4 of the 5 runs without a retreat, the dog killed the zombie in 10–13 turns. Against the E0 baseline (7–10 turns, 16–20 damage), kill time was similar or slightly longer, and the dog took no damage in several runs. This is not a formal E1 rerun, and end-of-run HP is partly unknown because there is no summary before each refill.
2. **Log noise while waiting behind the player.** Every action while waiting logged `step_failed acceptable=0`; waiting and being blocked look the same.
3. **`none` as killer is a non-creature cause.** The experimenter debug-killed neither #9 nor #13. Both were bleeding, so they are read as bleeding deaths. E5 confirmed that debug kills also show `none`.
4. **REGROUP while adjacent.** Before runs 3 and 7 the dog entered REGROUP at player distance 9 while adjacent to a zombie, and broke off. The experimenter had moved in between, so this is not read as a fault of the dog's judgment alone. This belongs to E5.

Follow-up: `step_failed` while waiting is now a single `hold`. A "player is between" flag on flee logs and a "set HP to 35%" menu item will be added if a later experiment revisits the low-HP retreat.

### 2026-10-05 E3 (engine delegation probe)

Log: `config/debug.log` 00:15–00:19. Dog #10, probe ON. Of 6 REGROUP episodes, 3 had no enemy and 3 happened while fighting a zombie. No save/reload (E4) was done.

| Situation | REGROUP episodes | `probe_result` | Player distance |
| --- | --- | --- | --- |
| No enemy | 3 | all 37 `kept=true` | returned 14→4, 10→4, 21→4 |
| Fighting (#18) | 1 | all 13 `kept=false` | moved away 9→12 |
| Fighting (#19) | 1 | 11 of 20 `kept=true` | 12→15 while fighting, back to 4 after the zombie died |
| Fighting (presumably #20) | 1 | 14 of 29 `kept=true` | held at 10 while fighting, back to 4 after the zombie died |

**Verdict: the engine keeps the destination only when it has no target.** With no enemy, the destination set by `set_move_target` before returning false was kept, and the dog returned using the engine's pathfinding. While fighting, the destination was replaced every action and the dog moved away from the player; once the zombie died it was kept again. The replacement was constant within an episode, so it is presumed to be the fought zombie's position; the log has no zombie position to confirm this.

Conclusions:

1. **With no enemy, delegate the return to the engine.** It brings pathfinding, which beats DoGS's one-tile steps.
2. **With an enemy in sight, DoGS moves the dog itself.** `set_move_target` and `set_target` do not change the engine's target choice. The same applies to keeping distance in the Guard role.
3. Targeting cannot be delegated either. To take on a specific enemy, DoGS moves next to it itself, then uses the engine's bite or a control attack while that enemy is the only one adjacent.

Further observations:

4. **Damage while delegated.** In the #18 episode the engine kept fighting 9–12 tiles from the player, and the dog's HP fell from 26 to 12, because the probe replaced the normal REGROUP movement.
5. **Low-HP retreat oscillation.** In the retreat that followed, RETREAT→DEFAULT→RETREAT repeated three times at roughly 4-turn intervals: when the zombie briefly left sight, "no visible enemy" released the retreat, and the dog re-entered when it reappeared at 5 tiles. No damage meanwhile (HP held at 12). It ended waiting behind the player (`hold`), and the player killed the zombie.

### 2026-10-05 E4 (state persistence)

Log: `config/debug.log` 00:30–00:33. Trained dog #10 and untrained dog #20. Saved around turn 1325963 and reloaded at 00:32:46.

| Item | Result | Evidence |
| --- | --- | --- |
| Entity numbers | Kept | Still logged as #10 and #20 after reload |
| Number counter (`mod_storage`) | Kept | After reload a new zombie became #23, continuing from #22 |
| Training state | Kept | #10 used control attacks right after reload |
| Tactical state (`dogs_state`) | Kept | No `from=none` transition after reload; a lost value would have logged one on the first action |
| Attack cooldown values | Not observed directly | The first control attack after reload (turn 1325974) came after the original cooldown had expired anyway. Same per-entity value storage, so likely kept, but unverified |
| DoGS attacks on the untrained dog | None recorded | #20 killed two zombies with normal attacks and has no `special` record. `special` only records attacks DoGS invokes, so engine use would not appear in this log; that the engine skips disabled attacks rests on the binding docs (`src/catalua_bindings_creature.cpp`, `ef0eced`) |

**Verdict: E4 passed.** Cooldown persistence was not observed directly, and disabling on the untrained dog is confirmed only indirectly from the log and source docs.

### 2026-10-05 E5 (leash and oscillation), first run

Log: `config/debug.log` 00:38–00:44. Dog #10. The experimenter walked among and away from zombies, and cleaned up some zombies along the way, play-style.

**Verdict: E5 failed.** Delegated returns clashed with the engine's target tracking, and the dog ended up as far as 60 tiles from the player.

1. **Mismatched delegation condition.** In REGROUP, DoGS delegated the return to the engine whenever no enemy was visible within 8 tiles. The engine, however, was targeting a zombie farther out and replaced the destination with it (`probe_result kept=false` 257 times). Whenever the enemy came within 8 tiles, DoGS stepped back one tile (`step kind=regroup`); once it left, the engine moved toward the zombie. The dog made almost no progress while the player kept walking, and the distance grew to 21, 60 and 40 (end of log). No fight or damage occurred (HP 30, no adjacent enemy). E3's conclusion itself held; the implementation was wrong to judge the engine's target by DoGS's 8-tile perception.
2. **REGROUP/DEFAULT round trips.** With no enemy, as the player walked, DEFAULT (distance 4) → REGROUP (distance 9) → DEFAULT repeated about every 10 turns: the engine's loose following lets the gap reach 9 before the return. REGROUP's minimum hold (3 turns) was respected. A 2-turn DEFAULT (turn 1326165→1326167) happened inside the episode in item 1.
3. **Play-style data.** The dog killed zombie #24; the player killed #25 and #26. At turn 1327104 the dog entered the low-HP retreat at HP 0.33, waited within 2 tiles of the player (`hold`), and the player killed the zombie, matching E2.
4. **Untrained dog #20's death** was logged with `killer=none`. The experimenter debug-killed it, so debug kills also show `none`; `none` alone cannot separate bleeding deaths from debug cleanup.

Fix: REGROUP now delegates only when no hostile monster is visible at any range. When the engine is seen replacing the destination, delegation stops for 5 turns and DoGS steps itself; with no way to detect off-sight targets (scent or sound tracking), the replaced destination is the signal. E5 will be rerun after the fix.

### 2026-10-05 E5 (leash and oscillation), second run

Log: `config/debug.log` 00:50–00:54. Dog #10. Rerun after fixing the delegation condition. The experimenter killed zombies directly in run 1, cleaned them up by debug in run 2, and ended run 3 without killing any.

| Item | Result |
| --- | --- |
| REGROUP episodes | 48, all returned to DEFAULT (within 4 tiles of the player) |
| Return time | 4–24 turns, median 9 |
| Maximum player distance | 18. It jumped from 1–2 tiles over the previous 5 turns, so this looks like a teleport rather than walking. The dog returned through engine delegation in 24 turns |
| Engine delegation | 2 episodes, both kept the destination (`probe_result` 0 times) |
| DoGS steps | 46 episodes. Even with no enemy within 8 tiles, DoGS steps when a farther zombie is visible |
| Step failures | `step_failed` 5 times, all with a zombie nearby; movement resumed shortly |

**Verdict: E5 passed.** The first run's runaway (up to 60 tiles) did not recur, and REGROUP's minimum hold (3 turns) was respected.

Observations:

1. **The sawtooth remains.** DEFAULT spans had a median of 5 turns, and 10 were shorter than 3 turns. A walking player alone can hardly widen the gap from 4 to 9 in 2 turns, so the engine presumably moved the dog toward a distant target during DEFAULT. This follows from the Free role following the engine's target choice and is left to the Guard role.
2. **Engine delegation is rarely used.** In open terrain a distant zombie is almost always visible, so the delegation condition (no enemy visible at any range) is seldom met. Whether DoGS's one-tile steps get stuck among obstacles was not tested.
3. **Play-style data.** Both low-HP retreats (HP 0.37, 0.33) waited within 2 tiles of the player and released after the player killed the zombie, matching E2. Zombie #31's `killer=none` is the run-2 debug cleanup (confirmed by the experimenter).

## 7. Working rules

- Every change cycle starts by analyzing the previous play log. No feature is added without reading the log.
- Loading success or mock-check passes are not reported as play verification.
- Do not move on to the next feature (LURE etc.) before an experiment meets its success criteria.
- This document records plans and results, not work journals or assertion counts.
