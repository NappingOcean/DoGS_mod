# LURE mission

Visually lure an exposed enemy away from its group. Sound-based group attraction is outside the core feature set because it can attract nearby enemies together.

## Flow

1. Select an enemy at the group edge.
2. Deliberately enter its sight.
3. Confirm that it actually pursues the dog.
4. Lead it away from the player.
5. Once separated, move sideways out of the pursuit axis.
6. Return by a detour without leading the enemy back to the player.

A straight return after gaining distance is insufficient. A **BREAK_CONTACT** phase is required. Use a multi-turn state machine with per-instance mission and phase state.

## Abort conditions

- Little remaining escape space
- Increasing encirclement risk
- Too many pursuers
- New enemies blocking the exit
- HP or danger thresholds exceeded
- Major player movement or a new threat to the player

Survival takes priority over mission completion; switch to ESCAPE / RETREAT. Numerical thresholds remain undecided.

Related: [Risk and positioning](risk-and-positioning.md), [pursuit identification and movement constraints](lua-and-movement.md).
