# Roadmap and open questions

A modular laboratory MVP is implemented. Data/script loading and Lua fixtures pass on redhot 2026-10-04; live gameplay validation remains pending. See [MVP scope and checks](mvp.md).

## Implementation order

1. Vanilla dog overrides and lua_ai connection
2. Per-instance training state
3. Local enemy detection and risk assessment
4. NORMAL: ASSIST / INTERCEPT / SKIRMISH / RETREAT / REGROUP
5. Custom Takedown
6. Ankle Tear and dedicated leg-wound effect
7. Multi-turn LURE mission
8. Minimal extra Lua bindings justified by playtesting

## Verification status

All source-level items were inspected; see [the audit](source-verification.md). Integration, persistence, callback dispatch, attacks, and effects are confirmed in source. Pursuit identity and waypoint execution have documented limits. Other mods can replace the same definitions, so compatibility remains conditional.

Runtime checks remain: verify untrained fallback and first-action disabling, save/load mission state, exercise attack/effect immunity and armor, waypoint movement, LURE, and named mod combinations. The MVP supplies debug controls and log events for these checks; they are not yet completed in live gameplay.

## Open design questions

Training and UI, supported dog types, risk scores and transition thresholds, attack values/resistance/cooldowns, wound IDs and stacking, and detailed LURE phases/contact-breaking conditions remain undecided.

## Gameplay criteria

Dogs avoid group centers, withdraw before encirclement, support the player, and return safely. LURE separates an edge enemy and breaks pursuit before returning. Judge attacks by control and mobility-disruption value.

[Documentation index](index.md).

Source evidence and remaining runtime checks: [BN source verification](source-verification.md).
