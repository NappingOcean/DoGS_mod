# Engine notes: BN behavior DoGS relies on

[한국어](../ko/engine-notes.md) · [Contents](index.md)

BN behavior the implementation relies on, at BN commit `ef0eced` (redhot `2026-10-04-0345`). Labels: [source] confirmed in source, [runtime E#] confirmed in a play log ([experiments](experiments.md)), unverified. Codex's earlier audits are [source-verification](source-verification.md) and [combat-hooks](combat-hooks.md) (at `e0e25e9`).

## Mod loading and Lua

- [source] While a mod loads, `package.path` points at its folder; it is cleared after loading ([catalua.cpp:491][load], [:503][unload]). Modules are therefore required during loading and kept as locals; gameplay callbacks never `require`.
- [source] The module searcher sends `lib.*` and `bn.lib.*` to `data/lua/lib/`; other names are looked up in the mod folder, then the game folder ([catalua_loader.cpp:110][loader]). `package.loaded` is shared by all mods, so DoGS modules use the `dogs.` prefix.
- [source] Each mod's table in `game.mod_storage` is saved with the world and refilled into the same table on load ([catalua.cpp:236][storage]), so a reference captured during loading stays valid. [runtime E4] The entity-number counter continued across save and reload.
- [source] Per-entity values (`set_value`/`get_value`) are strings saved with the Creature ([bindings_creature:309][setvalue]); a missing key reads as an empty string. [runtime E4] Training, state and numbers persisted.
- [runtime] `--check-mods` can exit with code 0 after a Lua load error. The check script also treats `Error` in the output as failure.

## lua_ai callback

- [source] `monster::move` calls the `lua_ai` callback first. On true with position and moves unchanged, it deducts 100 moves. On false or nil it continues with the normal `plan`/`decide`/`execute` ([monmove.cpp:1871][move], [:124][runlua]).
- [source] Each action has one special-attack budget; when Lua spends it with `use_special_attack`, the scheduler does not attack again in that action.
- [runtime E0] Overriding `mon_dog` with a same-ID self `copy-from` and adding `lua_ai` and `extend.special_attacks` loaded and worked.

## Pet AI targets and destinations

- [source] A friendly monster's `plan` re-picks the best-rated hostile monster as its target every action ([monmove.cpp:626][plan]).
- [source] A `docile` friendly monster picks no target in `plan` ([monmove.cpp:516](https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monmove.cpp#L516)). The existing dog whistle toggles this effect.
- [source] `set_move_target(pos)` only sets a destination. `set_target(creature)` only copies the creature's current position as the destination ([bindings_creature:526][setmove], [:533][settarget]).
- [runtime E3] After setting a destination and returning false, the engine keeps it only while it has no target (37/37); with a target it replaces it with the target's direction.
- [runtime E5] The engine targets enemies beyond DoGS's 8-tile perception. "The engine has no target" cannot be known directly from DoGS.

## Special attacks

- [source] Binding docs ([bindings_creature:456][special]): `special_attack_ready` checks only enabled state and cooldown. True from `use_special_attack` means the actor handled the attempt, not that it hit; the cooldown resets on true. Disabled attacks are skipped by the engine's scheduler, and the enabled state is saved.
- [source] The generic melee actor (`melee_actor::call`) returns a miss early when `hit_spread < 0`. On a hit it deals damage and applies JSON effects only when actual damage is positive ([mattack_actors.cpp:394][actor]).
- [source] `Creature::deal_melee_attack` calls the target's `on_dodge` when `hit_spread <= 0`, which fires the `on_creature_dodged` hook ([creature.cpp:694][dealmelee], [:1407][ondodge]). Monsters do not override `on_dodge`.
- [runtime E6] Bash 2 was fully absorbed by the fat zombie's bash armor 5, so the JSON knockdown never applied.

## Hooks

| Hook | Where it fires and payload | DoGS use |
| --- | --- | --- |
| `on_creature_melee_attacked` | Monster normal melee ([monster.cpp:2596][monmelee]) and character melee ([melee.cpp:1778][charmelee]), after hit and damage resolution. `char`, `target`, `success`. Not fired by generic actors | `melee`, `player_melee`, `player_attacked` logs |
| `on_creature_dodged` | `Creature::on_dodge`. `char` (the dodger), `source` | Detecting Takedown misses |
| `on_mon_death` | Monster death ([monster.cpp:3813][death]). `mon`, `killer` | `death` log |
| `on_shoot` | After a shot is processed ([ranged.cpp:1579][shoot]). `shooter`, `target_pos`, `shots`, `gun`, `ammo` | Firing-line avoidance (planned) |

- [runtime E2, E5] Bleeding deaths and debug kills both have no `killer` (`none`); the log cannot tell them apart.

## Perception and coordinates

- [source] A monster's attitude toward another monster comes from `monster::attitude_to` ([monster.cpp](https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monster.cpp)): faction hate means hostile; morale below 0 or anger below 10 means neutral. Timid animals (e.g. the spideer, morale -5, aggression -99) therefore see the dog as neutral and fall outside DoGS's enemy perception (hostile to both the dog and the player).
- [source] `sees` checks distance, light and terrain transparency; the checked path has nothing for other creatures blocking sight ([creature.cpp:455][sees]).
- [runtime E1] `get_pos_ms` is reality-bubble local and changes when the map shifts. That is harmless within one decision, but positions stored across turns use absolute coordinates via `abs_pos()` or `gapi.bub_to_abs` ([bindings_creature:240][abspos], [bindings_game:497][bub2abs]).

## Combat facts

- [source] A downed monster's dodge is 0 ([monster.cpp:3086][dodge]). [runtime E6] The player hit downed zombies 5/5.
- [source] Projectiles skip friendly creatures only within 1 tile of the shooter; friendlies farther along the line get an unintentional-hit roll ([ballistics.cpp:546][ballistics]).
- [source] Aiming and firing finish within one player action, and monsters do not act in between. `Character::last_target` is not exposed to Lua.
- [source] Flesh monsters regenerate 0.25 HP per hour, doubled when well fed ([monster.cpp:3607][regen]).
- [source] Lua has `add_effect(effect, duration, [bodypart], [intensity])`, `is_immune_effect` and `get_size()` (`MonsterSize`: TINY–HUGE) ([bindings_creature:289][addeffect], [:365][getsize]).

## Data

- [source] Monster JSON has no size field. Size is computed at load from `volume`: up to 7.5 L TINY, 46.25 L SMALL, 77.5 L MEDIUM, 483.75 L LARGE, above that HUGE ([monstergenerator.cpp:321](https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monstergenerator.cpp#L321), [:412](https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monstergenerator.cpp#L412)). Effects can add a size bonus ([monster.cpp:4256](https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monster.cpp#L4256)).
- [source] `heavysnare` and `lightsnare` are referenced in C++ ([monster.cpp:145][snare]) but have no JSON effect definition; listing them in the effect ID check fails it.
- Monster numbers ([mammal.json:918][mondog], [zed-classic.json:52][zombie], [:312][fat]):

| ID | HP | Speed | Notes |
| --- | --- | --- | --- |
| `mon_dog` | 30 | 150 | `HIT_AND_RUN` and others. Labrador mutt |
| `mon_zombie` | 80 | 70 | Volume 62.5 L (MEDIUM), weight 81.5 kg |
| `mon_zombie_fat` | 95 | 55 | Bash armor 5. Same volume and weight as `mon_zombie` (MEDIUM) |

[load]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua.cpp#L491
[unload]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua.cpp#L503
[loader]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua_loader.cpp#L110
[storage]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua.cpp#L236
[setvalue]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua_bindings_creature.cpp#L309
[move]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monmove.cpp#L1871
[runlua]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monmove.cpp#L124
[plan]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monmove.cpp#L626
[setmove]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua_bindings_creature.cpp#L526
[settarget]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua_bindings_creature.cpp#L533
[special]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua_bindings_creature.cpp#L456
[actor]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/mattack_actors.cpp#L394
[dealmelee]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/creature.cpp#L694
[ondodge]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/creature.cpp#L1407
[monmelee]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monster.cpp#L2596
[charmelee]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/melee.cpp#L1778
[death]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monster.cpp#L3813
[shoot]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/ranged.cpp#L1579
[sees]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/creature.cpp#L455
[abspos]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua_bindings_creature.cpp#L240
[bub2abs]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua_bindings_game.cpp#L497
[dodge]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monster.cpp#L3086
[ballistics]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/ballistics.cpp#L546
[regen]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monster.cpp#L3607
[addeffect]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua_bindings_creature.cpp#L289
[getsize]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua_bindings_creature.cpp#L365
[snare]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monster.cpp#L145
[mondog]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/data/json/monsters/mammal.json#L918
[zombie]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/data/json/monsters/zed-classic.json#L52
[fat]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/data/json/monsters/zed-classic.json#L312
