# Control attacks: Takedown and Ankle Tear

[한국어](../ko/attacks.md) · [Contents](index.md)

Labels: [design] decision, [source] confirmed in BN source, [runtime E#] confirmed in play. When the attacks are used (opportunity and follow-up) is in [behavior design](design.md) section 5.

## Division of roles

| Attack | Intent | Tactical role |
| --- | --- | --- |
| Takedown | Dart between the legs or body-check to knock the enemy down | Short, immediate control. A downed enemy has 0 dodge, so the player and dog hit it easily |
| Ankle Tear | Bite and tear the ankle or calf | Sustained mobility loss that hampers pursuit, return and escape |

[design] Both attacks aim at control rather than damage. The infection bite actor (`bite_actor`) is not used: it carries infection and toxic-flesh poisoning logic, which does not fit physical control. The engine's `LUNGE` is not used either: its knockdown is probabilistic, so it is not reliable control.

## Common implementation

- [design] Both are generic melee actors ([`dogs.json`](../../DoGS_mod/json/dogs.json)), added with `extend.special_attacks` on a same-ID override of `mon_dog`.
- [design] DoGS owns the cooldowns instead of the engine. After use it stores the "next usable game turn" in a per-entity value (`dogs_next_<attack ID>`). It enables the attack and sets the engine cooldown to 0 only at the moment of use, executes, and disables it again. [runtime E4] Per-entity values survive save and reload.
- [source] The generic melee actor applies JSON effects only after positive actual damage; when armor stops all damage, no effect applies.

## Takedown

| Item | Value |
| --- | --- |
| Damage | bash 2 |
| Move cost / cooldown | 100 / 8 turns |
| Knockdown | 2 turns, applied from Lua |
| Chance by size | tiny/small/medium 100%, large 50%, huge 0% |
| Targets | any enemy that is not huge |

**Resolution.** [design, 2026-10-05]

1. A watch is set just before the attack. If the target raises the dodge hook (`on_creature_dodged`) during the attack, it missed.
2. If it did not miss and the target is not immune to knockdown, `downed` is applied from Lua for 2 turns with the size chance. The target goes down even when armor reduces the damage to 0.
3. The result goes to `outcome` in the `special` log: `dodged`, `immune`, `resisted_SIZE`, `knocked_SIZE`.

**Evidence.**

- [runtime E6] The fat zombie (bash armor 5) absorbed all of bash 2, so the knockdown written in the JSON never applied. Knockdown was therefore moved from the JSON to Lua.
- [source] The actor returns a miss when `hit_spread < 0`. The target's dodge handling calls the dodge hook when `hit_spread <= 0`, and monsters do not override it. An exact 0 is a hit for the actor but read as a miss here, erring toward no knockdown.
- [source] A downed monster's dodge is 0. [runtime E6] The player hit all 5 swings at downed zombies (24/28 against standing ones).
- **unverified:** the new resolution (Lua application, size resistance) has not been checked in play. The check is E7 in [experiments](experiments.md).

## Ankle Tear

| Item | Value |
| --- | --- |
| Damage | cut 4 |
| Move cost / cooldown | 100 / 8 turns |
| Effects | bleed 20 turns, `dogs_ankle_wound` 10 turns |
| `dogs_ankle_wound` | speed bonus -20 (not a 20% reduction), max intensity 1, max 10 turns |

- [design] A dedicated effect expresses wound-related mobility loss; unrelated slowing effects are not reused.
- [source] `speed_mod` applies as a monster speed bonus, not a ratio.
- [source, earlier audit `e0e25e9`] Bleed immunity checks require the WARM flag and flesh material. `mon_zombie` has both and bleeds. JSON `iflesh` is insect flesh, not a zombie material. Other zombies need their own definitions checked.
- The effects come from JSON, so they do not apply at 0 damage. [runtime E6] The fat zombie took 1 damage.

## Attack choice

Set by the attack mode in the menu (`dogs_attack_mode`). Implementation: `choose_attack` in [`policy.lua`](../../DoGS_mod/dogs/policy.lua).

| Mode | Choice |
| --- | --- |
| auto (default) | Takedown if the target is a Takedown target and standing; otherwise Ankle Tear if the target has no ankle wound; otherwise leave it to the engine's normal bite |
| takedown | Takedown only, when the target is a Takedown target and standing |
| ankle | Ankle Tear only |

## Open questions

- Whether 50% for large targets and 2 turns of knockdown are right.
- How Ankle Tear effects stack and actually apply by armor and immunity (not checked in play).
- The attack's hit roll uses the actor default (the monster's melee skill). The dog's hit rate has not been measured.
