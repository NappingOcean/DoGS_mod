# Combat paths and Lua hook coverage

[한국어](../ko/combat-hooks.md)

> **Historical record.** A source audit by Codex at revision `e0e25e9`, kept as written. For the facts the current implementation relies on, see [engine notes](engine-notes.md) (at `ef0eced`).

Source audit, 2026-10-04. Revision: `e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800`. The installed executable is `ef0eced`; this audit does not claim binary-level tracing of that other revision. Hook declarations were checked against actual emitters and shared callees, not treated as proof of coverage. No gameplay experiment was run for this audit.

## Generic melee actor versus normal monster melee

They are separate callers, not wrappers around each other. JSON `attack_type=melee` creates a melee_actor; bite_actor inherits melee_actor. `monster::melee_attack(target)` forwards to its accuracy overload, not to melee_actor.

```text
melee_actor::call
  -> find_target / actor move cost
  -> target.deal_melee_attack (accuracy/dodge)
  -> select_body_part -> target.deal_damage
  -> actor.on_damage (positive damage only) -> JSON effects
  -> target.on_hit

monster::melee_attack
  -> normal attack cost / monster flags / base melee damage
  -> target.deal_melee_attack (accuracy/dodge)
  -> target.deal_melee_hit
       -> block_hit / mounted-target redirection
       -> deal_damage -> on_hit
  -> check_dead_state
  -> on_creature_melee_attacked
```

The generic actor's find_target also explicitly requires adjacency (mattack_actors.cpp:380); do not assume it is a reach attack.

Shared functions: deal_melee_attack, deal_damage, and on_hit (through different paths). Sharing these does **not** propagate on_creature_melee_attacked: that emitter sits in the normal attack caller. Creature::deal_damage applies armor, calculates damage and invokes virtual apply_damage; neither that function nor monster::apply_damage emits a universal Lua damage hook. Monster::on_hit invokes native defensive behavior, not a universal Lua attack-source event.

Differences include independently defined move costs, accuracy, damage, HIT_AND_RUN behavior, blocking/rider handling and extra effects. DoGS's two JSON melee actors consequently do not emit the normal monster melee hook. Use their explicit Lua invocation/result logs for their outgoing actions.

Evidence: [src/mattack_actors.cpp:394](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/mattack_actors.cpp#L394), [src/monster.cpp:2451](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monster.cpp#L2451), [src/creature.cpp:715](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/creature.cpp#L715), [src/creature.cpp:1267](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/creature.cpp#L1267), [src/monster.cpp:4420](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monster.cpp#L4420), F[src/mattack_actors.cpp:394](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/mattack_actors.cpp#L394)Y, [src/mattack_actors.h](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/mattack_actors.h).

## Coverage matrix

| Hook | Actual emitter and information | Important limitation |
| --- | --- | --- |
| on_creature_melee_attacked | Normal monster melee and Character melee; char=attacker, target, success | Actor melee bypasses it; success is the hit test, not positive HP damage; normal monster early returns skip it |
| on_creature_dodged | Creature/Character on_dodge; char=defender, source=attacker, difficulty | Useful even for generic actor melee misses; not an all-attempts or damage event |
| on_creature_attacked_by_character | Character melee; Creature projectile processing when source is player/NPC; actual target plus source and success | Projectile early miss/avoid exits skip it; projectile success=true is not damage>0; a raw monster projectile source fails the player/NPC gate |
| on_shoot | ranged::fire_gun after shots resolve; shooter, aimed target_pos, shots, gun, ammo | No actual hit target, damage or hit list; shots can be zero |
| on_throw | After throw resolution; thrower, target_pos, throw_from_pos, thrown | Aimed position is not an actual hit target |
| on_mon_effect_added / on_mon_effect | Monster effect processing with mon and effect | Require [src/monster.cpp:4046](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monster.cpp#L4046)_LUA_ON_ADDED/[src/monster.cpp:4046](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monster.cpp#L4046)_LUA_ON_TICK flags; no attacker identity |
| on_mon_death | Monster death processing with mon and killer | Terminal event, not an every-hit history; fake sources cannot automatically be treated as an original monster |

Evidence: [src/monster.cpp:2596](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monster.cpp#L2596), [src/melee.cpp:1778](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/melee.cpp#L1778), [src/creature.cpp:1407](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/creature.cpp#L1407), [src/creature.cpp:1253](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/creature.cpp#L1253), [src/creature.cpp:849](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/creature.cpp#L849), [src/ranged.cpp:1579](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/ranged.cpp#L1579), [src/ranged.cpp:1989](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/ranged.cpp#L1989), [src/monster.cpp:4046](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monster.cpp#L4046), [data/json/flags.json:2647](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/data/json/flags.json#L2647), [src/monster.cpp:3813](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monster.cpp#L3813). Registered names are listed in [src/catalua_hooks.cpp:8](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/catalua_hooks.cpp#L8); bindings/doc declarations are not emission sites.

Boundary caution: deal_melee_attack invokes on_dodge for hitspread<=0, whereas generic/normal monster callers treat hitspread>=0 as a hit. An on_creature_dodged event alone must not be used as an exact final miss/damage verdict at the zero boundary.

## Monster firearms and other special attacks

Gun actors create a temporary standard_npc at the monster's position, mark it fake, and call ranged::fire_gun. The projectile keeps that temporary Character as source. Therefore **on_creature_attacked_by_character can identify the actual target in this path**, despite the attacker logically being a monster. Resolve an original monster by the source position during the callback; do not retain the temporary Character userdata after the callback. on_shoot separately identifies gun use and aimed position.

The exported Lua API exposes is_npc/as_monster but not is_fake. Position matching is a candidate association, not independent proof of proxy identity; a Lua implementation must preserve that uncertainty.

This corrects the earlier investigation's omission of the projectile emitter of on_creature_attacked_by_character. Correlating on_shoot with HP is not the only option for firearm hits.

Other special attacks must be classified by their actual call path. A hardcoded attack can call monster::melee_attack and emit its hook (the grab path does); another can directly call deal_damage or projectile_attack and bypass it. Neither "special attack" nor "melee" alone establishes hook coverage. Raw monster-source projectiles do not satisfy the Character-source projectile hook gate. Spell/effect/environment damage likewise requires its own path audit.

Evidence: [src/mattack_actors.cpp:805](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/mattack_actors.cpp#L805), [src/ranged.cpp:1443](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/ranged.cpp#L1443), [src/monattack.cpp:2998](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monattack.cpp#L2998).

## Consequences for DoGS

1. Keep normal melee observations, distinguishing hit-test success from actual HP loss.
2. Add actual-target Character/projectile observations before relying on aimed-position correlation; map fake firearm NPC sources immediately.
3. Use on_shoot/on_throw as attack-attempt context, not proof of a hit.
4. Observe generic actor dodges where useful; explicit DoGS actor invocation is already known for outgoing control attacks.
5. Preserve clearly marked uncertainty for direct-damage and raw-monster-projectile paths rather than attributing them to an arbitrary nearby enemy.

Items 2-4 describe follow-up integration work. This audit changes documentation and investigation rules, not the current gameplay callbacks.
