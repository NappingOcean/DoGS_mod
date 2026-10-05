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

## Decision (2026-10-05)

Keep the generic melee actor and apply downed from Lua after a hit, so it lands even when armor stops all damage. Resistance is by size (tiny/small/medium 100%, large 50%, huge 0%). Damage is bash 2, downed lasts 2 turns, cooldown is 8 turns. Evidence and implementation: "Takedown resolution" in the [experiment plan](../claude/experiment-plan.md).

Related: [Ankle Tear](ankle-tear.md), [Roadmap](roadmap.md).

Source evidence and remaining runtime checks: [BN source verification](source-verification.md).
