# Experiments

[한국어](../ko/experiments.md) · [Contents](index.md)

Procedures and results of the experiments. Results come from analyzing play logs (`config/debug.log`); log events are listed in the [development guide](development.md). Numbers are the order of execution.

## Background: state before the rebuild

Observed in an actual play log of the pre-rebuild code (2026-10-04 22:03–22:06, state before commit `9316c3e`):

- The dog never attacked except with special attacks. It stood next to a zombie, used Takedown (2 damage) every 8 turns, and took 6–7 damage roughly every 5 turns. Its combat contribution is below a vanilla dog.
- The later fix that backs off during cooldown (COOL_OFF) reduces damage contribution further and abandons protecting the player.
- At the leash boundary, REGROUP and SKIRMISH alternated every turn (22:06:15–19). There is no hysteresis.
- The custom one-tile movement has no pathfinding and repeatedly logged `move_blocked` (21:46).
- A base max HP of 3,000 effectively never triggers the 50% retreat threshold, which invalidates survival-judgment experiments.

From this diagnosis, the implementation that took over the dog's turn was dropped and rebuilt as a judgment layer over the stock pet AI ([behavior design](design.md) section 1). The earlier code is in commit `1c1ac60`.

## Common conditions

A separate test world, open terrain, daytime. The number of runs is set per experiment: one by default, more only when a result is unclear. Player attacks and HP healing are set per experiment.

| Experiment | Status | Player attacks | HP healing |
| --- | --- | --- | --- |
| E0 Baseline | done | none | between runs only |
| E1 Solo control | done (failed) | none | between runs only |
| E2 Low-HP retreat | done | kills the zombie once the dog is behind the player | between runs only |
| E3 Engine delegation probe | done | cleanup if needed | allowed mid-run |
| E4 State persistence | done | cleanup if needed | allowed mid-run |
| E5 Leash and oscillation | done (second run passed) | cleanup if needed | allowed mid-run |
| E6 Guard | done (second run passed) | fights alongside | between runs only |
| E7 New Takedown resolution | done (largely passed) | fights alongside | between runs only |
| E8 Harass v0 probe | first attempt invalid; rerun planned | fights the zombie the dog is not holding | allowed mid-run |
| E9 Multiple enemies | planned | fights alongside | between runs only |
| E10 v0.1 check play | done | varies by item | between runs only |

## Procedures

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

Roles were implemented after E3 (Guard implemented, Harass planned). The experiments below come after role implementation.

### E6 Guard (done: first run partial pass, second passed)
- Setup: two regular zombies, apart from each other, about 6 tiles from the player. The player fights them with a melee weapon. Repeat with a vanilla dog and a Guard-role dog.
- Measure: damage taken by the player, turns until the player has killed both zombies, turns the dog spent more than 3 tiles from the player (`player` in `summary`).
- Check: does the dog close on zombies approaching the player (`step kind=intercept`)? Does it avoid chasing distant zombies while guarding? Do control attacks turn into openings for the player?
- Success: the player takes less damage than with the vanilla dog, and the dog stays within 3 tiles of the player except while returning.

### E7 New Takedown resolution check (done: largely passed)
- Background: Takedown's knockdown moved to Lua with size resistance ([control attacks](attacks.md)). Not yet checked in play.
- Setup: a Guard-role dog, the player fighting alongside with a melee weapon. Fight a regular zombie and a fat zombie separately. For a LARGE target use the zombie moose (`mon_zoose`: 92.5 L, HP 210, speed 140, melee skill 6, bash armor 6). Its HP yields many Takedown attempts, and bash armor 6 absorbs all of Takedown's bash 2, so "knocked down at 0 damage" is checked in the same runs. Set the attack mode to takedown. The boomer (`mon_boomer`: HP 40, bile) is the alternative. The zombie deer (`mon_zeer`, speed 240) outruns the dog, so the low-HP retreat cannot work; it is not used this time.
- Also check: blowing the existing dog whistle logs `docile on=true` and the dog stops attacking.
- Measure: the distribution of `outcome` in `special` (knocked, resisted, dodged, immune); `player_melee downed=true` hits on downed targets.
- Check: when `outcome=dodged` appears, did the game message also show a miss?
- Success: the fat zombie goes down on a Takedown hit (`knocked_MEDIUM`), and `dodged` matches the misses in the game messages.

### E8 Harass v0 probe (first attempt invalid; rerun planned)
- Purpose: does Harass v0 actually hold an enemy up, and how long does a zombie chase a dog that keeps its distance?
- Setup: two regular zombies. The dog in the Harass role. The player fights one with a melee weapon (the player must be engaged for harassing to start) and leaves the other to the dog.
- Measure: `chases` in `track` (whom the target is attacking: dog or player) and how long it stays on the dog, `toward` (is the target's destination nearer the dog or the player), the change in target–player distance, `on_player` (enemies on the player at once), time until `harass_end`, damage taken by the dog.
- Decides: the holding distance (2–3 tiles now), the harass range (8 tiles now), and conditions where harassing does not work.
- Also check: the docile stop order and the menu Call back.
- The first attempt ran in the Free role before Harass existed and was invalid (see Results).

### E9 Multiple enemies: Guard versus Harass (planned)
- Setup: 3–4 regular zombies approach the player. The player fights alongside with a melee weapon. Repeat with a Guard-role dog, a Harass-role dog and a vanilla dog.
- Measure: the maximum number of enemies on the player at once; hits and HP the player takes; turns the dog spent adjacent to 2+ enemies; adjacent count and count within 3 tiles when encirclement avoidance (RETREAT) starts.
- Success: with the Harass dog, the maximum number of enemies on the player at once is lower than with the Guard or vanilla dog, and the dog never stays adjacent to 2+ enemies for more than one turn.
- To judge: does encirclement avoidance start early enough to count as "without hesitation"? If late, change the entry thresholds.

The old E8 (a 5-zombie crowd, per role) is not run; E9 replaces it, because Guard and Harass never enter a group by design.

### E10 v0.1 check play (done)
Before the v0.1 release, check the new pieces and regressions of existing behavior on the reference build. Items were cut on 2026-10-17: what the self-tests or finished items already cover is not replayed.

- Setup: a test world with debug mode on. Create dogs and enemies with BN's debug menu and tame dogs with dog food. Set training levels with DoGS debug → Dog tools → "Training level override".
- Run the remaining items in one play session, in the order B → I → F·J. Afterwards, give one line listing the dogs and enemies used per item (for example "B: 2 zombies, I: 1 pit bull"). The log is read after the last `event=load`.

| Item | Setup | Check | Pass |
| --- | --- | --- | --- |
| B Guard regression | E6 setup (two zombies, 6 tiles, player in melee). Labrador at override 2. 1 run | `trained on=true`, `[DoGS] Trained dog` in the monster's info, `intercept` after `melee`, damage to the dog | No repeated `intercept` onto the same tile after a bite. Within 3 tiles of the player in combat |
| I Wild animal attack | Labrador at override 1. One untamed pit bull mix spawned 3–5 tiles away; let the dog bite first. The player does not attack. 1 run | `summary enemies=` while being bitten, the dog's `melee target_type=mon_dog_pitbullmix` | No `enemies=0` while being bitten, and the dog bites back |
| F·J Whistle and debug off | Refill the dog's HP first. The whistle (craft under Other → Tools or spawn it). One dog at override 3 | Debug on: whistle → the role list includes Harass → choosing Free logs `menu source=whistle role=free`. Debug off: the whistle on the same dog gives the "does not know the signals yet" notice (the override is off, so level 0), and `[DoGS] Trained dog` leaves the monster's info. Save and reload | After turning debug off, the only `[DoGS]` line is `event=debug on=false` and there are no state messages. Still off after reloading |

Finished and removed items:

- A Training levels, C Low-HP retreat: passed (see Results).
- D Weight-ratio Takedown: passed. Twenty level-2 attempts showed `chance=71` and a 70% knockdown rate, and level 3 logged `chance=76`. Per-level values come from the same formula, which the self-tests cover, so no more level-3 samples are collected.
- E Breeds: removed. A's border collie (#1) logged `decide` at level 1, which shows the per-breed JSON is attached. The weight-ratio rule (no attempt for a Chihuahua) is covered by the self-tests.
- G Puppy growth, H BN training: removed. They take long. DoGS only reads BN's level every action and uses it as is without an override (A's pit bull #3 logged `level=0`). If a problem shows up in ordinary play after the release, it will be looked at then.
- B's return walk and second run: removed. Return was not changed and was checked in E10-B.
- J's attack-message wording: removed. With debug off the override is off too, so it would need a BN-trained dog.

- On a failure, fix and rerun only that item. B, I and F·J passing meets the v0.1 release condition.

## Results

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
4. **Coordinates.** `get_pos_ms` is reality-bubble local and shifts when the map shifts (#4 appears to move 11 tiles in one turn). This is harmless within one decision, but E3's probe destination stored across turns needs `abs_pos`.

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

### 2026-10-05 E6 (Guard), first run

Log: `config/debug.log` 01:23–01:29. Dog #10, first in the Guard role against 7 zombies (#32–#38), then with training OFF (vanilla) against 3 zombies. The player fought alongside with a melee weapon.

| Condition | Zombies | Killer | Damage taken by the dog | Player distance (`summary`, while fighting) |
| --- | --- | --- | --- | --- |
| Guard | 7 | all 7 avatar | 0 (HP stayed 30) | 1–4 |
| Vanilla | 3 | all 3 the dog | 10 (30→20) | 4–7 |

- **Guard:** every zombie was killed by the player within 1–5 turns after a Takedown (#32 4 turns, #33 3, #34 5, #35 1, #36 2, #37 1, #38 4). `step kind=intercept` 17 times. No REGROUP or low-HP retreat. Distance 4 appeared once, apparently while returning.
- **Vanilla:** the dog fought and killed on its own, drifting up to 7 tiles from the player. The experimenter observed the vanilla dog ignoring the guard duty and running toward distant zombies.
- **Experimenter's observation:** while a zombie was downed, its attacks were easier to dodge and the player's attacks landed more often. This matches the source finding that a downed monster's dodge is 0 (`src/monster.cpp`).

**Verdict: partial pass.** The dog stayed within the radius, and control turned into kills by the player. The success criterion "damage taken by the player" is not in the log and could not be compared. Logging was added for the player's melee swings (`player_melee`, including whether the target was downed), melee attacks on the player (`player_attacked`), and player HP in `summary`; E6 will be rerun with it. With training turned off in the menu, the role still reads guard but the dog behaves as vanilla.

### 2026-10-05 E6 (Guard), second run

Log: `config/debug.log` 08:37–08:43. Dog #10. In the Guard role against 5 regular zombies (#39, #40, #43, #44, #45) and 2 fat zombies (`mon_zombie_fat`, #41, #42), then with training OFF (vanilla) against 8 regular zombies. The player fought alongside with a melee weapon. `player_hp` is the sum of body-part HP.

| Condition | Zombies the player fought | Hits taken by the player | Player HP lost | Damage taken by the dog | Dog–player distance |
| --- | --- | --- | --- | --- | --- |
| Guard, regular zombies | 5 | 2 | about 6 | 4 | 1–3 |
| Guard, fat zombies | 2 | 3 | 19 | 17 | 1–3 |
| Vanilla, regular zombies | 5 (the dog killed the other 3) | 5 | 21 | 16 | 1–5 |

The player's melee hit rate (`player_melee`):

| Target state | Hits / swings |
| --- | --- |
| Downed regular zombie | 5 / 5 |
| Standing regular zombie (Guard and vanilla combined) | 24 / 28 |
| Fat zombie (never downed) | 7 / 11 |

**Verdict: E6 passed.** Against regular zombies, the player took 2 hits (about 6 HP) fighting alongside the Guard dog versus 5 hits (21 HP) with the vanilla dog. The Guard dog stayed within 3 tiles of the player. The sample is small, and the vanilla runs differ in that the dog killed 3 zombies on its own.

Observations:

1. **Downed zombies were always hit:** 5/5 against 86% (24/28) for standing ones. Same direction as the experimenter's observation, on a small sample.
2. **Without Takedown, guarding helps little.** Fat zombies are not Takedown targets (only `mon_zombie` is), so they got only Ankle Tear (1 damage). The player took 3 hits from the two of them, and the dog took 17 damage. The Takedown target range (size and resistance rules) is still an open design question. (Later decision: apply the knockdown from Lua and resist it by size; see [control attacks](attacks.md). Checked in E7.)
3. **Downed flag on the killing blow.** Some killing swings logged `downed=false` (#39). Whether the zombie had stood up or death processing cleared it was not checked.

### 2026-10-05 E7 (new Takedown resolution)

Log: `config/debug.log` 12:25–12:34. Dog #10, Guard role, the player fighting alongside. Opponents: regular zombies #51, #54, #55, fat zombie #52, zombie moose #53. The existing dog whistle was blown several times.

| Target | Takedown result (`outcome`) | Damage | Notes |
| --- | --- | --- | --- |
| Regular zombie | `knocked_MEDIUM` ×4 | 2 | One (#54) was a target killed by that blow |
| Fat zombie #52 | `knocked_MEDIUM` ×1 | **0** | Went down even though armor stopped all damage |
| Zombie moose #53 | `knocked_LARGE` ×1, `resisted_LARGE` ×1 | 0 | |

**Verdict: largely passed.** Knockdown at 0 damage and size resistance worked. Miss detection was not verified: none of 7 Takedowns logged `dodged`, and the log alone cannot tell whether none missed or detection failed.

Observations:

1. **Large enemies get up quickly.** The zombie moose was already standing the turn after it went down (1335894); regular zombies stayed down 2–3 turns and the fat zombie 2. [source] Monsters roll to stand with their melee dice (`monster.cpp`), so strong monsters rise sooner. Against the moose, the knockdown barely turned into openings for the player.
2. **Ankle Tear does nothing to the zombie moose.** Cut 4 against its cut armor 4 dealt 0 damage and no wound (JSON effects need damage). Against the fat zombie it dealt 1 and the wound applied.
3. **The zombie moose was dangerous.** It hit the player 7 of 9 times (about 23 HP). The dog fell from 30 to 5 HP (0.17), retreated to wait beside the player, and survived.
4. **Player hits on downed targets:** regular zombies 2/2, fat zombie 1/2; 8/9 together with E6.
5. **Docile:** `docile on/off` was logged with each whistle, and DoGS used no control attacks while docile. But the engine kept the docile dog biting the adjacent zombie (19 normal attacks across two windows, killing zombie #55). Vanilla docile only stops picking new targets; it does not stop a fight already in contact.
6. **Knockdown on a dead target.** When Takedown's damage killed the target, it still applied the knockdown and logged `knocked`. Fixed: a dead target is logged `killed` and not knocked down.

### 2026-10-05 E8 (Harass probe), first attempt, invalid

Log: `config/debug.log` 17:21–17:27. Dog #10, Free role, fighting two or so zombies (#56–#61) continuously.

**Verdict: invalid.** The experiment design was at fault. The log had no zombie positions or destinations, so "whom does the zombie pursue" could not be judged, and with Harass not yet implemented the dog fought in contact instead of keeping distance. Harass v0 and the `track` log were implemented first, and E8 will be rerun as a v0 probe.

Salvaged:

1. **Docile stop order checked.** While docile (turns 1336062–1336070) the dog stepped away from the adjacent zombie twice (`docile_disengage moved=true`), with no normal attacks logged; it resumed attacking once docile ended. One sample.
2. **Encirclement timing.** Fighting two zombies, the dog entered RETREAT four times, each time already adjacent to 2 enemies; its HP fell from 30 to 15. This looks later than "without hesitation before encirclement"; E9 will judge it.
3. **Wait-log noise.** During the low-HP wait, a moving player made flee steps and waits alternate, so `hold` was logged almost every action. A logging issue, not a behavior one.

### 2026-10-17 E10-A (training levels)

Log: `config/debug.log` 20:03–20:34. Game build 2026-10-16-0238 (`f9586ef`). Level 0 ran in the session before the last `event=load` (20:15). The experimenter removed dog #1 (border collie) with the debug menu. Dog #3 (pit bull mix) kept biting Labrador #2, so the experimenter tamed it partway through.

| Level | Dog | Turns | Result |
| --- | --- | --- | --- |
| 0 | Labrador #2 | 1325048–1325200 | No `decide`, `step` or `special`. Killed the zombie with 12 engine bites |
| 1 | Labrador #4 | 1325692–1325899 | `decide` and `step`, no `special`. Killed zombie #5 with engine bites |
| 2 | Labrador #4 | 1325899–1325928 | `dogs_takedown outcome=knocked` at 1325910 |

**Verdict: A passed.**

Observations:

1. **A trained dog died to an animal it did not count as an enemy.** While level-1 Guard Labrador #2 was bitten by wild pit bull mixes (turns 1325280–1325530), every `summary` read `enemies=0`. #2 never bit back. Its HP fell 30→21, and after a menu refill 30→13→8→3. It died at 1325531 with `killer=mon_dog_pitbullmix`. At level 0 it had bitten a pit bull (1325224, 1325236). Meanwhile `probe_result engine_target=true` was logged, so the engine did see a target. There were at least two pit bulls: tamed #3 was more than 25 tiles away when #2 died, and #3 itself bit another pit bull (1325479).
   - Cause [source]: stock dogs have `aggro_character: false`, so when another monster's bite angers them they still ignore the player ([engine notes](engine-notes.md)). Perception then required hostility to both the dog and the player, so it missed the pit bull. With no enemy, Guard spent the turn waiting, so the engine never got to bite back.
   - Fix: perception now counts monsters hostile to the dog or the player. Guard also hands the turn to the engine when the engine's own target is adjacent. E10-I will check this.
2. **Takedown chance ignored the override.** Override 2 logged `chance=61`, the level-0 value: the code read BN's `training_level`. It now uses the overridden level. Item D now uses levels 2 and 3 instead of level 0, which has no special attacks.
3. **Guard steps back and forth.** At 1325856–1325876, `intercept from=89,86 to=89,85` repeated 8 times. The dog moves in, and the next action puts it back. The level-1 dog took about 190 turns to kill one zombie. Item B looks at this.
4. **The low-HP retreat still works.** #4 entered RETREAT at HP 0.23 and waited within 2 tiles of the player. The 5 `hold` lines in 15 turns are the same log noise seen in E8.
5. **`step_failed kind=intercept` was logged twice per turn.** This is not a duplicate. A stock dog has speed 150, so it acts once or twice per turn, and each action is logged (corrected in E10-B).
6. After the Takedown (1325910) the player was 4 tiles away, so the dog returned instead of biting the downed zombie. This is the Guard radius (3) working as designed.

### 2026-10-17 E10-B, C, D

Log: `config/debug.log` 20:52–21:02. Same build. Dog #4 (Labrador, Guard). Runs were split from the log.
- Override 2: B (zombies #7 and #8, then #9 and #10), D with the dog fighting alone (#11, #12), C (#13)
- Override 3: D (#14), zombie moose #15

HP was refilled from the menu. It was not refilled between #11 and #13, which is why the low-HP retreat happened at #13.

**B Guard and return (2 runs): mostly passed. To be rerun once `HIT_AND_RUN` is blocked.**

| Run | Zombies | Hits on the player | Damage to the dog | Kills |
| --- | --- | --- | --- | --- |
| B-1 | #7, #8 | 0 | 21 (30→9, about 6 turns) | both by the player |
| B-2 | #9, #10 | 1 | 0 | player 1, dog 1 |

- In combat the player distance was 1–3. It reached 4 or more only during retreat or with no enemy around. `step kind=intercept` occurred 76 times.
- There was one REGROUP (1326174→1326181). The dog came back from distance 15 to 4 in 7 turns. Just before it entered, the distance went from 6 to 15 in 4 turns; the cause has not been checked.
- The 21 damage to the dog in B-1 is far more than in E6 Guard (4 over five zombies). Observation 1 gives the cause.
- At 1326080–1326090 `player_hp` dropped from 1034 to 1032 with no `player_attacked` line. The cause has not been checked.

**C Low-HP retreat (1 run, #13): passed.**
- RETREAT started at HP 0.37 (1326385).
- On the next action the dog waited within 1 tile of the player (`hold`).
- Its HP then stayed at 11.
- The retreat ended 4 turns after the zombie died (1326397).
- The retreat during B-1 (HP 0.30) was different: the dog circled 3–4 tiles from the player and only started waiting after 16 turns, against the E2 limit of 10. With two zombies near the player, it apparently found no tile behind the player. E9 will look at this again.

**D Weight-ratio Takedown: level 2 passed; too few level-3 samples.**

| Level | `chance` | Attempts | Knocked | Resisted |
| --- | --- | --- | --- | --- |
| 2 | 71 | 20 | 14 (70%) | 6 |
| 3 | 76 | 3 | 2 | 1 |

- `turns=2` was correct throughout.
- The zombie moose drew no Takedown attempt (ratio 0.25), only two Ankle Tears (0 damage).
- A Takedown that killed its target logged `outcome=killed` (1326121), which confirms the E7 fix.
- D was later marked passed: per-level values come from the same formula, which the self-tests cover (E10 procedure).

Observations:

1. **Stock hit-and-run fights against Guard.** [source] Because of the `HIT_AND_RUN` flag, a stock dog flees for 4 turns after every bite ([engine notes](engine-notes.md)). When Guard moves the dog back into contact, the engine pulls it out again without biting.
   - `intercept` repeatedly stepped onto the same tile (1326196, 1326198).
   - In the same turn the dog broke off after a control attack, Guard moved it straight back into contact (1326013, 1326015).
   - E10-A observation 3 has the same cause.
   - Fix: dogs at level 1 or more get the permanent effect `[DoGS] Trained dog`, which blocks `run` ([philosophy](philosophy.md)).
2. **Log lines are written per action.** Several `hold` and `step_failed` lines in one turn come from speed 150. E10-A observation 5 is corrected.
3. **The zombie moose was dangerous.** The dog fell back at HP 0.23 within 4 turns, and the player's HP dropped from 1021 to 994, as in E7.

### 2026-10-21 E10-B (rerun), I

Log: `config/debug.log` 21:34–21:40 (played 2026-10-17). Dog #4, override 3, Guard.

**B: passed.** Four zombies (#16–#19). `trained on=true` (1326452). Hit-and-run is gone: once in contact the dog bit 3–6 times in a row and killed a zombie alone in about 14 turns (190 before). Damage to the dog 10, hits on the player 3, player distance 1–3 in combat. One problem remained: after a control attack the dog broke off and Guard put it back in contact in the same turn (7 times). Guard no longer breaks off ([behavior design](design.md)).

**I: passed (on what it checks).** Pit bull #20 counted as an enemy from the start (`enemies=1–2`), and the dog moved in and used Takedown (dodged, 1327775). In the next 2 turns its HP fell from 20 to 2; it fell back and died 30 turns later (1327809). The cause is the experiment design. "The player does not attack" contradicts the retreat's premise that the player deals with the pursuer, and the dog started without recovering from B. Not rerun.

Limit [source]: the debug override does not give BN's per-level HP, melee and dodge multipliers, which use the real `training_level` (`monster.cpp:1360`). A Labrador at override 3 has HP 30; at BN level 3 it would have about 52. All E10 survival results come from this condition.

### 2026-10-21 E10-F, J

Log: `config/debug.log` 23:47–23:51. Dog #21 (Labrador), override 3. Same build.

**F·J: passed.** With debug on, the whistle's role list offered Harass, and each choice logged `menu source=whistle role=harass/free/guard`. After debug was turned off, the only `[DoGS]` line was `event=debug on=false`. After reloading it stayed off (no lines beyond the load markers). The experimenter confirmed on screen the level-0 notice and that `[DoGS] Trained dog` went away. There was no combat, so removing the break-off from Guard was not checked in play.

**E10 done.** The v0.1 release condition (B, I, F·J passed) is met.
