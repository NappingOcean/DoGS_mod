# AI architecture

Separate multi-turn objectives from immediate actions in three layers.

## Mission layer

| Mission | Purpose |
|---|---|
| NORMAL | General tactical support |
| LURE | Visually attract and separate an exposed enemy |

## Tactical layer

NORMAL selects among:

| Action | Purpose |
|---|---|
| ASSIST | Support the player's current engagement |
| INTERCEPT | Cut off an enemy approaching the player |
| SKIRMISH | Engage an exposed enemy at the group edge and disengage |
| RETREAT | Withdraw from danger |
| REGROUP | Return near the player |

## Atomic layer

Execute MOVE, Takedown, Ankle Tear, ordinary movement/withdrawal, and necessary short attacks. A tactical action can include approach, attack, and disengagement.

Prefer hard safety vetoes followed by simple action scores and hysteresis to reduce oscillation. Keep utility scoring manageable.

Related: [Risk and positioning](risk-and-positioning.md), [LURE](lure.md).
