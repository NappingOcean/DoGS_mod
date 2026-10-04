# Takedown

## Intent

Provide immediate control through **downed**, rather than damage. The dog destabilizes the enemy by moving between its legs or striking with its body.

A successful attack should reliably knock the enemy down. This does not mean every enemy is always susceptible: large or stable enemies may need success conditions or resistance checks.

## Actor direction

Do not use the existing hardcoded LUNGE. Prefer a dedicated attack using a generic melee actor or a custom actor as needed. Avoid the generic bite actor where its infection logic conflicts with physical control.

## Confirmed technical findings

- Generic melee applies effects only after positive actual damage. Armor can prevent effects even with chance 100; zero-damage downed needs another application path.
- LUNGE has probabilistic downed and can add move budget at range instead of moving directly. It does not meet reliable Takedown requirements.
- Downed sets monster dodge to zero. In stock AI, getting up ends remaining moves, with recovery depending on melee dice/sides.
- bite_actor includes grabbed-wound infection and toxic-flesh attacker poisoning.

Actor choice, resistance, damage, duration, and cooldown remain open.

Related: [Ankle Tear](ankle-tear.md), [Roadmap](roadmap.md).

Source evidence and remaining runtime checks: [BN source verification](source-verification.md).
