# Ankle Tear

Bite and tear the ankle or lower leg to reduce mobility. This is a physical wound, not an infection attack.

## Candidate implementation

- Generic melee actor
- Cut damage
- Bleed
- Dedicated leg-wound / mobility-penalty effect

Use an effect whose meaning is wound-related mobility loss instead of repurposing unrelated slowing effects. Consider a short duration, reduced `speed_mod`, and stacking limits if needed.

## Reported technical findings — verify in BN

The discussion reported that SPEED modifiers affect monsters and that bleed periodically damages them and leaves blood. Verify this in the target BN version.

| Attack | Role |
|---|---|
| Takedown | Immediate, short control |
| Ankle Tear | Sustained disruption of pursuit, return, or escape |

Related: [Takedown](takedown.md), [Philosophy](philosophy.md).
