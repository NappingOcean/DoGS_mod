# Ankle Tear

Bite and tear the ankle or lower leg to reduce mobility. This is a physical wound, not an infection attack.

## Candidate implementation

- Generic melee actor
- Cut damage
- Bleed
- Dedicated leg-wound / mobility-penalty effect

Use an effect whose meaning is wound-related mobility loss instead of repurposing unrelated slowing effects. Consider a short duration, reduced `speed_mod`, and stacking limits if needed.

## Confirmed effects

speed_mod loads as SPEED and changes monster speed bonus. Bleed has damage/blood processing but requires a susceptible target: the immunity check requires WARM and flesh. JSON defines iflesh as Insect Flesh; mon_zombie is flesh with WARM and is not immune. Check variants individually. Retain bleed as a candidate alongside the dedicated mobility penalty. Generic melee still requires positive actual damage for either effect.

| Attack | Role |
|---|---|
| Takedown | Immediate, short control |
| Ankle Tear | Sustained disruption of pursuit, return, or escape |

Related: [Takedown](takedown.md), [Philosophy](philosophy.md).

Source evidence and remaining runtime checks: [BN source verification](source-verification.md).
