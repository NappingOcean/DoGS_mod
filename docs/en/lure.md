# LURE mission (not implemented)

[한국어](../ko/lure.md) · [Contents](index.md)

Labels: [design] decision, [source] confirmed in BN source, [runtime E#] confirmed in play.

## Purpose

[design] Visually lure an enemy at the edge of a group and separate it. Sound-based luring of a whole zombie group is outside the core feature set, because sound draws nearby enemies too and does not separate individuals.

LURE is not a role but a one-off mission order from the player ([behavior design](design.md) section 6).

## Flow

1. Pick an enemy at the edge of the group.
2. The dog deliberately enters that enemy's sight.
3. Confirm that the enemy actually pursues the dog.
4. Once pursued, lead it away from the player.
5. When far enough, slip sideways out of the pursuit axis (**BREAK_CONTACT**).
6. Return by a detour so the enemy is not led back to the player.

Simply gaining distance and returning straight to the player is not allowed.

[design] Mission and phase are a multi-turn state machine kept in per-entity values.

## Abort conditions

- Little escape room left.
- Rising encirclement risk.
- Too many enemies on the dog.
- A new enemy appears on the escape route.
- HP or risk thresholds exceeded.
- The player moves far or comes under a new threat.

When in danger, survival takes priority over the mission and the dog switches to RETREAT. Numeric thresholds are undecided.

## Implementation constraints found so far

- [source] `set_target` copies the target's current position as a destination; it does not keep tracking the target. No binding reads a monster's attack target.
- [runtime E3, E5] The engine overwrites a DoGS-set destination whenever it has a target, so movement during LURE must be DoGS's own one-tile steps, which currently have no pathfinding.
- [source] An enemy's `move_target()` and movement are only evidence of pursuit, not a confirmed pursuit target. They must be rechecked across actions and save/load.
- [design] Object permanence (the last turn an enemy was perceived) already exists. LURE may also need the pursuer's last position.
- [source] `sees` tells whether the dog sees the target; LURE also needs whether the enemy sees the dog. Sight checks distance, light and terrain transparency; other creatures do not block sight.
- [design] The wounded dog's retreat brings the enemy to the player (design section 4), the opposite of LURE's rule. Which one wins when the dog drops to low HP during LURE must be decided.
