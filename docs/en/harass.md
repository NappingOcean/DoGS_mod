# Harass role: delaying the next enemy (not implemented)

[한국어](../ko/harass.md) · [Contents](index.md)

Labels: [design] decision, [source] confirmed in BN source (`ef0eced`), [runtime E#] confirmed in play, unverified.

## Definition

[design, 2026-10-05] Harassing means **buying time against the next enemy to arrive, close to the player**. While the player fights one enemy or regroups, the dog holds up the enemy that would arrive next. Cutting enemies out of a group and taking them far away is not the goal.

## Flow

1. **Pick the target.** While the player is engaged, pick the enemy that would arrive next, within 7–8 tiles of the player. It must be exposed, not in the middle of a group.
2. **Control.** Go out to it and apply Takedown or Ankle Tear.
3. **Hold it up (small-scale luring).** Do not head straight back to the player. Keep out of the enemy's reach while leading it to chase the dog alone, so it does not reach the player soon. Reapply a control attack when the cooldown is ready and it is safe.
4. **Finish.** Once the player has dealt with the current enemy and regrouped, return to the player.

**Constraints**

- Do not get too far from the player (within about 8 tiles).
- Do not enter the enemy group or end up adjacent to other enemies.
- On encirclement risk or low HP, stop harassing and follow the safety veto.

## Why this form

- [source] Zombies end up converging on the player: losing the dog, they follow the player's scent (the scent map is written only at the player's position). The dog cannot change an enemy's destination for long, but it can change **when** it arrives.
- [runtime E6] Facing enemies one at a time, the player was barely hit. The danger is two or more arriving at once.
- [source] The dog's speed is 150, twice a zombie's 70, and an ankle-wounded zombie drops to 50. The dog has room to lead the enemy around and manage the distance.
- The scale is small (7–8 tiles from the player), so the dog and the player stay within each other's support. The risk of being picked off separately is low.

## Difference from Guard

| | Guard | Harass |
| --- | --- | --- |
| Enemy taken on | The one on or approaching the player now | The one that will arrive next |
| Range | 3 tiles from the player | 7–8 tiles from the player |
| Attacks | Normal bites included; quick removal | Control attacks only; no close fighting |
| Movement | Stays close | Keeps distance so the enemy chases the dog alone |
| Goal | Remove the enemy in front together | Buy time so enemies do not arrive at once |

## Open points and risks

- **Knowing when to finish.** The dog cannot know when the player has finished regrouping. Candidates: no enemy on the player for several turns, or the player calling it back from the menu.
- **Does the zombie keep chasing the dog?** [source] Monsters re-pick their target every action; if the player gets closer to the zombie, it may switch to the player. How long a zombie chases the dog is unverified; a small probe experiment is needed before implementing.
- **Distance to keep.** The distance that keeps the dog out of reach yet still chased (e.g. 2–3 tiles) is to be set by experiment.
- **Movement.** [runtime E3, E5] While enemies are visible, movement is DoGS's one-tile steps. Over short distances this is fine, but cluttered terrain needs checking.
- **Measures.** The maximum number of enemies on the player at once; turns until the harassed enemy reaches the player.

## Shelved: cutting enemies out of a group

[design, shelved 2026-10-05] The original idea was to lure the outermost enemies of a group far away, bite their ankles so they straggle, and return (LURE in earlier documents). It was shelved for these limits:

- The dog and the player get far apart, with a high risk of being picked off separately.
- [source] A zombie that loses the dog follows the player's scent back, so taking it far away does not keep it away.
- Luring by sight can draw every zombie that sees the dog, so separating just one is not guaranteed.
- Who is pursuing the dog cannot be read from Lua, and long-distance movement while enemies are visible has no pathfinding.
- One enemy per cycle means low throughput, and the player is alone and unguarded meanwhile.
