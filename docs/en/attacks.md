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
| Weight ratio | Dog weight ÷ target weight, both the monster definition's `weight` ([engine notes](engine-notes.md), Data) |
| Attempt | weight ratio 0.3 or more |
| Knockdown chance | rises linearly from 50% at ratio 0.3 to 100% at 0.6; +5% per BN training level (max 100%) |
| Knockdown duration | 2 turns; +1 at ratio 0.6 or more, +1 at training level 4 or more. Applied from Lua |
| Targets | any enemy that meets the attempt condition, flying ones included (read as struck and knocked out of the air) |

**Judged by weight ratio.** [design, 2026-10-17] The dog tries a Takedown only on an enemy it can bring down. Whether it is worth trying is set by the dog/target weight ratio, and so are the success and the knockdown duration.

- Deciding the attempt by volume (apparent size), to model the dog misjudging by eye, was considered and not adopted. Takedown is a trained move, and not being fooled by appearance is part of the training. [source] Most BN monsters have an even weight/volume ratio (engine notes, Data), most breeds define no volume and inherit the Labrador's 30 L, and Lua can read only the five-step size, not the volume.
- BN training level stands for the knack of striking the target's center of mass. [source] BN's training multiplier applies only to the hit skill (does the bite land), so it does not overlap DoGS's bonus (does a landed bite bring the target down). The felt success rate is the product of the two.
- Small breeds get no separate rule. With a low ratio the dog uses Ankle Tear or a normal bite instead.

Weight ratio examples (BN `weight`, training level 0):

| Dog | Zombie 81.5 kg | Zombie child 40.75 kg | Zombie moose 120 kg |
| --- | --- | --- | --- |
| Chihuahua 2.2 kg | 0.03, no attempt | 0.05, no attempt | 0.02, no attempt |
| Beagle, dachshund 10 kg | 0.12, no attempt | 0.25, no attempt | 0.08, no attempt |
| Collie 16 kg | 0.20, no attempt | 0.39, 65% | 0.13, no attempt |
| Labrador 30 kg | 0.37, 61% | 0.74, 100%, 3 turns | 0.25, no attempt |
| German shepherd 35 kg | 0.43, 72% | 0.86, 100%, 3 turns | 0.29, no attempt |
| Rottweiler 50 kg | 0.61, 100%, 3 turns | 1.23, 100%, 3 turns | 0.42, 69% |

A Labrador trained to its max level 3 has 76% against a zombie.

**Resolution.** [design, 2026-10-05]

1. A watch is set just before the attack. If the target raises the dodge hook (`on_creature_dodged`) during the attack, it missed.
2. If it did not miss and the target is not immune to knockdown, `downed` is applied from Lua with the chance and duration set by weight ratio and training level. The target goes down even when armor reduces the damage to 0.
3. The result goes to `outcome` in the `special` log: `dodged`, `killed` (the blow was fatal), `immune`, `too_heavy` (the ratio fell short at resolution), `resisted`, `knocked`. The last two carry `chance=` and `turns=`. `resisted_SIZE` and `knocked_SIZE` in logs before 2026-10-17 come from the size resolution.

**Evidence.**

- [runtime E6] The fat zombie (bash armor 5) absorbed all of bash 2, so the knockdown written in the JSON never applied. Knockdown was therefore moved from the JSON to Lua.
- [source] The actor returns a miss when `hit_spread < 0`. The target's dodge handling calls the dodge hook when `hit_spread <= 0`, and monsters do not override it. An exact 0 is a hit for the actor but read as a miss here, erring toward no knockdown.
- [source] A downed monster's dodge is 0. [runtime E6] The player hit all 5 swings at downed zombies (24/28 against standing ones).
- [runtime E7] The fat zombie went down at 0 damage; the zombie moose (LARGE) went down once and resisted once (under the size resolution; with the weight ratio a Labrador does not try it on a zombie moose). Miss detection was not verified because no miss occurred (unverified).
- [runtime E7, source] Large enemies get up quickly: the zombie moose was standing the next turn. Monsters roll to stand with their melee dice.

## Ankle Tear

| Item | Value |
| --- | --- |
| Damage | cut 4 |
| Move cost / cooldown | 100 / 8 turns |
| Effects | bleed 20 turns, `dogs_ankle_wound` 60 turns (one BN turn is one second) |
| `dogs_ankle_wound` | speed bonus -20 (not a 20% reduction), max intensity 1, max 60 turns; a new bite refreshes it |
| Targets | flying enemies (`flies()`) excluded: there is no ankle to reach |

- [design] A dedicated effect expresses wound-related mobility loss; unrelated slowing effects are not reused.
- [design, 2026-10-05] It was 10 turns at first. A real bite healing in 10 seconds was implausible and shorter than one Harass cycle (the player dealing with one enemy and regrouping), so it was raised to 60 turns. Not checked in play.
- [source] `speed_mod` applies as a monster speed bonus, not a ratio.
- [source, earlier audit `e0e25e9`] Bleed immunity checks require the WARM flag and flesh material. `mon_zombie` has both and bleeds. JSON `iflesh` is insect flesh, not a zombie material. Other zombies need their own definitions checked.
- The effects come from JSON, so they do not apply at 0 damage. [runtime E6] The fat zombie took 1 damage.

## Attack choice

Set by the attack mode in the menu (`dogs_attack_mode`). Implementation: `choose_attack` in [`policy.lua`](../../DoGS_mod/dogs/policy.lua).

| Mode | Choice |
| --- | --- |
| auto (default) | Takedown if the target is a Takedown target and standing; otherwise Ankle Tear if the target does not fly and has no ankle wound; otherwise leave it to the engine's normal bite |
| takedown | Takedown only, when the target is a Takedown target and standing |
| ankle | Ankle Tear only (never on flying enemies) |

## Open questions

- Whether the weight-ratio values (attempt 0.3, 100% at 0.6, floor 50%, +5% per training level, 2–4 turns downed) are right. The weight-ratio resolution has not been checked in play (it needs a check like E7 again).
- How Ankle Tear effects stack and actually apply by armor and immunity (not checked in play).
- The attack's hit roll uses the actor default (the monster's melee skill). The dog's hit rate has not been measured.
