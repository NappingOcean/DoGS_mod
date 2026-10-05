# Harass role: lure and straggle (not implemented)

[한국어](../ko/harass.md) · [Contents](index.md)

Labels: [design] decision, [source] confirmed in BN source (`ef0eced`), [runtime E#] confirmed in play, unverified.

## Definition

[design] Against a zombie group, the dog **lures the outermost enemy first, separates it from the group, leaves it straggling, and returns**. Biting the ankle with Ankle Tear to cut its mobility exists to make that straggling more reliable. What earlier documents called the LURE mission is this role.

Sound-based luring of the whole group is not used: sound draws nearby enemies too and does not separate individuals.

## Flow

1. Pick the outermost enemy of the group.
2. The dog enters that enemy's sight.
3. Confirm that the enemy actually pursues the dog.
4. Lead it away from the player, biting its ankle with Ankle Tear.
5. When far enough, slip sideways out of the pursuit axis (**BREAK_CONTACT**).
6. Return to the player by a detour so the enemy is not led back.

**Abort conditions:** escape room narrowing, rising encirclement risk, several enemies on the dog, a new enemy on the escape route, HP or risk thresholds exceeded, the player moving far or a new threat to the player. When in danger, survival comes before the role. Numbers are undecided.

## Strengths

- **Fewer enemies at once.** The group arrives one by one instead of all together. [runtime E6] Fighting one enemy at a time with the dog, the player took far fewer hits. The effect against a group has not been measured yet (E8 planned).
- **The dog is much faster.** [source] Dog speed 150, regular zombie 70, fat zombie 55. With the ankle wound (speed bonus -20) they drop to 50 and 35. Leading an enemy away and then outpacing it is physically possible.
- **Straggling works by delaying arrival.** [source] BN's scent map is written only at the player's position, so a zombie that loses the dog can eventually follow the player's scent back. But it returns slowed by the ankle wound and apart from the group, so the player can deal with it separately. Seen as desynchronizing arrival rather than removing the enemy for good, this matches the role's goal.
- **It fits the philosophy.** It contributes through positioning, separation and timing rather than damage.

## Limits

- **No guarantee of separating just one.** Luring by sight means any zombie that sees the dog may respond. The dog must position so only the outermost one sees it; with a tight group, several may follow (unverified).
- **Who is pursuing cannot be read directly.** [source] No Lua binding reads a monster's attack target; it must be inferred from the enemy's destination (`move_target`) and movement.
- **Shaken enemies come back.** [source] Only the player leaves scent. Even if the dog detours home, a zombie within scent range can return toward the player. What the dog can do is not lead it back and delay its arrival.
- **The ankle wound is short.** The wound lasts 10 turns, the cooldown is 8, and only one enemy is bitten at a time. With 0 damage through armor, no wound forms. The wound can wear off while leading the enemy away.
- **The dog is alone and exposed.** Away from the player there is no guarding. The low-HP retreat (behind the player) brings the enemy to the player, contradicting this role's rule; which wins at low HP during Harass must be decided. [source] Dogs barely regenerate, so one mistake lasts.
- **Long-distance movement is weak.** [runtime E3, E5] While enemies are visible, the engine overwrites DoGS-set destinations, so DoGS must step one tile at a time without pathfinding. Leading away and detouring back may get stuck among obstacles (unverified).
- **Low throughput.** One lure–separate–return cycle handles one enemy. A large group takes a long time, and the player is alone and unguarded meanwhile.

## Staged implementation proposal

1. **Stage 1, straggling only:** Ankle Tear the outermost or trailing members of a group approaching the player, then break off immediately. Buildable from existing parts (control attacks, disengage, object permanence). Measure: the time spread of the group's arrival at the player, and the maximum number of enemies on the player at once.
2. **Stage 2, lure and separate:** the full flow above. Needs pursuit detection, BREAK_CONTACT, detour return, and a multi-turn state machine in per-entity values.

## Implementation constraints

- [source] `set_target` copies the target's current position as a destination; it does not track the target.
- [source] An enemy's `move_target()` and movement are evidence of pursuit, not confirmation, and must be rechecked across actions and save/load.
- [source] `sees` tells whether the dog sees the target; whether the enemy sees the dog needs its own check. Sight depends on distance, light and terrain transparency; other creatures do not block it.
- [source] Zombies have the `SEES`, `HEARS` and `SMELLS` flags. In the monster faction table, the zombie faction does not list the dog faction as friendly or neutral. [runtime E0] Zombies attacked the dog.
- [design] Object permanence (the last turn an enemy was perceived) already exists; remembering the pursuer's last position may also be needed.
