# MVP laboratory

[한국어](../ko/mvp.md)

## Scope

The modular MVP supports **mon_dog (Labrador mutt)**, using a per-individual experimental training switch. DoGS does not raise base stats. Untrained dogs use stock AI after only the two DoGS attacks are disabled. This is a laboratory build, not the completed companion AI.

NORMAL labels: ASSIST when a target is adjacent to the avatar, INTERCEPT within three tiles, otherwise SKIRMISH. Target selection penalizes local clustering. These are provisional heuristics: ASSIST does not yet identify the player's current opponent, and INTERCEPT does not track approach velocity.

RETREAT overrides attacks at half HP, two adjacent hostiles, or four within three tiles. REGROUP applies beyond six tiles from the avatar or when no target exists. Movement tries adjacent empty tiles with lower threat and uses native movement costs/collision checks. This is greedy local movement; walls and dead ends can stop it. It has no multi-turn route planning or encirclement prediction. If no acceptable step exists, the dog waits. Immobilization, riding, leash/harness, stun, and pacification defer to stock handling. Visible hostile **monsters** are considered within eight tiles on the same level; hostile NPCs are not covered yet.

## Experimental attacks

| Attack | Damage | Cost / cooldown | Effect after positive damage |
| --- | --- | --- | --- |
| Takedown | 2 bash | 100 moves / 8 turns | downed, 2 turns |
| Ankle Tear | 4 cut | 100 moves / 8 turns | bleed, 20 turns; dogs_ankle_wound, 10 turns |

Takedown eligibility is deliberately limited to **mon_zombie** until size/resistance rules are designed. Automatic selection uses Takedown on an ordinary zombie that is standing; otherwise Ankle Tear. A forced Takedown mode waits on ineligible targets. A handled attack may miss or fail against armor: logs distinguish handling, actual HP damage, and effect presence. Native immunity still applies. Downed can end early when the target stands up.

The wound imposes an experimental **-20 speed bonus**, not a 20% reduction. Its maximum intensity is one and duration is capped at ten turns. This generic melee prototype does not anatomically select a monster ankle. No fall probability was added.

## Install and play

Run from the repository root on Windows:

```powershell
.\scripts\Install-Mod.ps1 -GameDirectory ..\game_redhot
```

This creates `mods/DoGS` as a junction to this repository's `mod` directory. Existing unrelated destinations are refused. Restart the game after changing scripts/data and enable **DoGS — Dogs of Good Sense (MVP)** in a disposable test world. Lua API 2 is required; the 2026-09-24 stable build was not used for validation.

1. Spawn and tame a Labrador mutt using normal game/debug tools.
2. Open **action_menu / Misc / DoGS laboratory**, select the dog, and enable experimental training. Attack mode and optional action messages are configured there. No remote item or manual snapshot is needed.
3. Test an ordinary zombie in an open area with automatic/Takedown-only/Ankle-Tear-only modes. Changing modes does not reset cooldowns.
4. Logs automatically record dog state changes before/after AI, a heartbeat every five turns, and visible monsters within eight tiles of a supported dog. Attack targets are recorded before/after attacks. Movement success and failed-step outcomes are automatic.
5. Test untrained dogs, low HP, nearby groups, obstacles, tied/downed states, and save/reload. These are live playtests, not implied by successful loading.

The log is the active user directory's **config/debug.log**. Search for `[DoGS]`. Enable INFO/LUA logging if necessary. `state` records persistent per-entity IDs, type, position, current/maximum HP, observed HP delta, speed, friendliness/training, tactical action, attack mode, effects, cooldowns, moves and game turn. HP delta is the net change since the previous observation; it is not an individual hit count or damage-source attribution. IDs distinguish multiple dogs of the same type and persist through normal creature value serialization; actual save/reload still needs testing.

`move` reports coordinates and cost; `move_blocked` reports unsuccessful local stepping; `attack` reports actor handling, actual damage and effects, with dog/target IDs. `action` retains the compact transition message. Nearby target states are logged on changes; periodic dog heartbeats provide context without user intervention. Disappearance/death and invisible targets are not yet monitored. Old saved remote items remain functional for compatibility, but the action menu is the supported workflow.

## Verification

Test environment: Windows x64 MSVC redhot **2026-10-04-0345**, commit `ef0eceda391d4d291b366e3bf2833b04c7342d72`. Lua API signatures were exported from this executable. The prior source audit remains pinned to `e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800`; these are separate revisions.

```powershell
.\scripts\Test-Mod.ps1 -GameDirectory ..\game_redhot
```

The checker uses an isolated temporary user directory, runs `--check-mods DoGS`, retains stdout/stderr/debug.log, and requires exit zero plus Lua success markers. **Passed:** data/script loading, ten policy assertions using native coordinate objects, eight guard assertions and four telemetry assertions with mock monsters, and finalized ID validity. Guard fixtures do not prove actual engine callback dispatch or combat.

**Pending live playtests:** movement/terrain costs, actor hit/miss and armor/immunity cases, first-turn behavior of real untrained dogs, effect processing/expiration, actual save/load, and compatibility with other mods. LURE, production training, additional breeds, and full path planning are not implemented. No live combat success is claimed.

## Files

`mod/json/` contains dog overrides, effects, and legacy debug items and action-menu controls. `mod/lib/` separates configuration, logging, policy, perception, movement, attacks, AI, and diagnostics, and automatic telemetry. `mod/tests/` contains load-time fixtures. `preload.lua` registers callbacks before JSON use; `finalize.lua` checks loaded definitions. See the [source audit](source-verification.md) for native behavior.
