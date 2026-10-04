# Takedown

## Intent

Provide immediate control through **downed**, rather than damage. The dog destabilizes the enemy by moving between its legs or striking with its body.

A successful attack should reliably knock the enemy down. This does not mean every enemy is always susceptible: large or stable enemies may need success conditions or resistance checks.

## Actor direction

Do not use the existing hardcoded LUNGE. Prefer a dedicated attack using a generic melee actor or a custom actor as needed. Avoid the generic bite actor where its infection logic conflicts with physical control.

## Reported technical findings — verify in BN

These were reported in the source design discussion, not verified against a pinned source revision:

- Existing LUNGE's probabilistic downed and distance handling do not meet the reliability goal.
- Generic melee effects reportedly require at least 1 actual damage, so zero-damage downed may need a custom actor or extension.
- Downed monsters reportedly spend actions getting up, stronger monsters recover more easily, and dodge becomes zero while downed.

Actor choice, resistance, damage, duration, and cooldown remain open.

Related: [Ankle Tear](ankle-tear.md), [Roadmap](roadmap.md).
