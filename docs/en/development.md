# Development guide

[한국어](../ko/development.md) · [Contents](index.md)

What you need to change the code or run an experiment. Paths are relative to the repository root.

## Repository layout

| Path | Contents |
| --- | --- |
| [`DoGS_mod/`](../../DoGS_mod/) | The mod (mod ID `DoGS`). The game's `mods/DoGS` points to this folder |
| [`docs/`](../) | Documentation (English `en`, Korean `ko`); change both together |
| [`scripts/`](../../scripts/) | Install and check scripts |
| [`AGENTS.md`](../../AGENTS.md), [`AGENT/research-rules.md`](../../AGENT/research-rules.md) | Agent working rules, commit trailers |

## Install and check

```powershell
.\scripts\Install-Mod.ps1 -GameDirectory <BN game directory>
.\scripts\Test-Mod.ps1 -GameDirectory <BN game directory>
```

- `Install-Mod.ps1` links the game's `mods/DoGS` to `DoGS_mod/` with a junction. It replaces only a junction to the old `mod/` and stops if anything else is there.
- `Test-Mod.ps1` runs `--check-mods DoGS` in a temporary user directory. It fails if the output contains `Error` or the load markers (`selftest scope=policy result=pass`, `load build=claude-rebuild`, `finalize result=pass`) are missing. BN can exit with code 0 after a Lua load error.
- A pass means data loading, ID checks and the pure policy checks passed. It is not play verification.
- After changing code, reload the world in the game to apply it.

## Modules

| File | Role |
| --- | --- |
| [`preload.lua`](../../DoGS_mod/preload.lua) | Loads modules; registers the AI callback, hooks, menu and periodic log; runs policy checks |
| [`finalize.lua`](../../DoGS_mod/finalize.lua) | Validates the dog type and effect IDs |
| [`json/dogs.json`](../../DoGS_mod/json/dogs.json) | `mon_dog` override: `lua_ai` and the two attacks. HP stays vanilla |
| [`json/effects.json`](../../DoGS_mod/json/effects.json) | The `dogs_ankle_wound` effect |
| [`dogs/ai.lua`](../../DoGS_mod/dogs/ai.lua) | Decision order ([behavior design](design.md) section 2), Guard, delegated return |
| [`dogs/policy.lua`](../../DoGS_mod/dogs/policy.lua) | Pure functions: state transitions, control window, attack choice, Takedown chance, Guard target, step ranking |
| [`dogs/perception.lua`](../../DoGS_mod/dogs/perception.lua) | Enemy scan and observations |
| [`dogs/movement.lua`](../../DoGS_mod/dogs/movement.lua) | One-tile steps: retreat, flee, disengage, regroup, intercept, kite |
| [`dogs/attacks.lua`](../../DoGS_mod/dogs/attacks.lua) | Attack choice and execution, per-entity cooldowns, Takedown resolution, dodge hook |
| [`dogs/role.lua`](../../DoGS_mod/dogs/role.lua) | Reading and toggling the role; Guard when unset |
| [`dogs/events.lua`](../../DoGS_mod/dogs/events.lua) | 10-turn summaries, melee records (dog and player), death records |
| [`dogs/menu.lua`](../../DoGS_mod/dogs/menu.lua) | action_menu |
| [`dogs/log.lua`](../../DoGS_mod/dogs/log.lua) | Log lines, entity numbers |
| [`dogs/config.lua`](../../DoGS_mod/dogs/config.lua) | All numbers, with comments naming the experiment behind each change |
| [`dogs/tests.lua`](../../DoGS_mod/dogs/tests.lua) | Policy-function checks at load; not evidence of engine behavior |

## Coding rules

- Modules are required only during loading, with the `dogs.` prefix. Gameplay callbacks never `require`. `lib.` is reserved for BN's shared library ([engine notes](engine-notes.md)).
- Decision rules are pure functions in `policy.lua`, testable without engine objects. When changing them, add checks to `tests.lua` and recompute expected values by hand.
- Always disable DoGS attacks before handing the action to the engine (returning false).
- Positions stored across turns use absolute coordinates.
- New effect or monster IDs are validated in `finalize.lua`.
- Log through `log.write`. Record decision events, not per-turn state dumps.

## Per-entity values

All are strings, saved and restored; missing keys read as an empty string.

| Key | Meaning |
| --- | --- |
| `dogs_id` | Entity number for logs, on dogs and on monsters that appear in records |
| `dogs_trained` | `"1"` means DoGS-trained |
| `dogs_role` | `"harass"` means Harass, `"free"` means Free; anything else means Guard |
| `dogs_attack_mode` | `auto` (or empty), `takedown`, `ankle` |
| `dogs_messages` | `"0"` silences state messages; on by default |
| `dogs_state`, `dogs_state_turn` | Current state and the game turn it was entered |
| `dogs_threat_turn` | Last game turn an enemy was perceived (object permanence) |
| `dogs_holding` | Marker so a low-HP wait is logged only once |
| `dogs_disengage` | Marker for the control follow-up |
| `dogs_docile` | Last logged docile state (so changes are logged once) |
| `dogs_next_<attack ID>` | Next usable game turn |
| `dogs_delegate_block` | Do not delegate the return to the engine until this game turn |
| `dogs_harass_target` | Entity number of the harassed target |
| `dogs_engaged_turn` | Last game turn an enemy was on the player (Harass auto-finish) |
| `dogs_recall_until` | Harassing stops until this game turn (menu recall) |
| `dogs_track_turn` | Marker so `track` is logged once per turn |
| `dogs_probe_dest`, `dogs_probe_player` | Delegated return destination (absolute) and the player distance at that time |

`next_id` in the mod storage (`game.mod_storage`) is the next entity number.

## Configuration

Values in [`config.lua`](../../DoGS_mod/dogs/config.lua). Change them only through experiments.

| Key | Value | Meaning |
| --- | --- | --- |
| `radius` | 8 | Enemy perception radius |
| `retreat.adjacent` / `nearby` | 2 / 4 | Encirclement: adjacent count / count within 3 tiles |
| `retreat.hp` / `flee` | 0.4 / 5 | Low-HP threshold / enemy distance that starts the retreat |
| `retreat.exit_nearby` / `hold` | 2 / 2 | Exit condition / minimum hold turns |
| `retreat.memory` | 5 | Object permanence (turns) |
| `regroup.enter` / `exit` / `hold` / `block` | 8 / 4 / 3 / 5 | Return entry and exit distances, minimum hold, delegation pause |
| `guard.radius` / `engage` | 3 / 2 | Guard distance / distance of enemies to engage |
| `harass.range` / `hold_min` / `hold_max` | 8 / 2 / 3 | Harass range / distance to keep from the target |
| `harass.crowd` / `finish` / `recall` | 1 / 3 / 10 | Exposure limit (other enemies nearby) / auto-finish turns / recall duration |
| `control_nearby` | 2 | Maximum enemies within 3 tiles for a control attack |
| `attacks.*.cooldown` | 8 | Attack cooldown (turns) |
| `takedown.duration` / `chance` | 2 / by size | Knockdown turns / chance by size |
| `summary_interval` | 10 | Summary period (turns) |

## Logging

Lines tagged `[DoGS]` in `config/debug.log` in the game user directory. Every line written during play carries `turn=` (game turn).

| Event | Content |
| --- | --- |
| `load`, `finalize`, `selftest` | Load markers |
| `decide` | State transition and basis: HP ratio, adjacent count, count within 3 tiles, nearest enemy, player distance |
| `step` / `step_failed` | One-tile step (kind: retreat, flee, disengage, regroup, intercept, kite) and risk score before/after |
| `hold` | Start of a wait during the low-HP retreat (once per wait) |
| `disengage` | Break-off attempt in the control follow-up |
| `docile` | Docile state changed (`on=true/false`) |
| `docile_disengage` | A step out of contact while docile (`moved`) |
| `special` | Attack ID, target, result (`outcome`), actual damage, downed/bleed/ankle flags |
| `melee` | The dog's normal attacks: target type, hit, target HP after |
| `player_melee` | The player's melee swings: target (numbered), hit, whether the target was downed, target HP |
| `player_attacked` | Melee attacks on the player: attacker, hit, player HP after (sum of body parts) |
| `summary` | Every 10 turns for every friendly Labrador mutt: trained, role, state, position, HP, player distance, nearby enemy count and HP sum, player HP, enemies on the player (`on_player`) |
| `probe_result` | Only when the engine replaced a delegated return destination |
| `death` | Deaths of dogs, monsters killed by dogs, and numbered monsters. Killer is a monster, `avatar`, or `none` (bleeding or debug kill) |
| `harass_target`, `harass_end` | Harass target picked; harassing finished |
| `track` | Each turn while harassing: target–dog and target–player distance, whom the target's destination is nearer (`toward`), enemies on the player |
| `menu` | Menu changes |

## Menu

action_menu → Misc → **DoGS laboratory**. With several Labrador mutts in sight, pick one from a list sorted by distance. The title shows the number, role, HP, state and cooldowns.

| No. | Item |
| --- | --- |
| 1 | Training on/off (tamed dogs only) |
| 2 | Attack mode cycle: auto → takedown → ankle |
| 3 | State messages on/off |
| 4 | Refill HP (for experiments) |
| 5 | Role cycle: Guard → Harass → Free |
| 6 | Call back: stop harassing for 10 turns and guard |

## Running experiments

- Procedures and results are in [experiments](experiments.md). Write a new experiment's setup, measurements and success criteria before starting.
- Every change starts from analyzing the previous play log. No feature is added without reading the log.
- Read the log after the last `event=load build=claude-rebuild`. Split runs by `menu` events (HP refill, training toggle).
- Record how the experimenter ended each run (direct kill, debug kill). `killer=none` alone cannot separate bleeding deaths from debug kills.
- Loading success or passing policy checks is not reported as play verification.

## Working rules

- Commit trailers follow [research-rules](../../AGENT/research-rules.md). Commit to `main` and push right after each commit.
- Change English and Korean documents together. Record experiment results in [experiments](experiments.md), and decisions in the [roadmap](roadmap.md) decision log and the relevant design document.
