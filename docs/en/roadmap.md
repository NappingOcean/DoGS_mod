# Roadmap and open questions

The project is in the design stage. Implementation is not yet verified. Check technical details against the target BN version.

## Implementation order

1. Vanilla dog overrides and lua_ai connection
2. Per-instance training state
3. Local enemy detection and risk assessment
4. NORMAL: ASSIST / INTERCEPT / SKIRMISH / RETREAT / REGROUP
5. Custom Takedown
6. Ankle Tear and dedicated leg-wound effect
7. Multi-turn LURE mission
8. Minimal extra Lua bindings justified by playtesting

## Verification tasks

- same-ID overrides, lua_ai, and extend.special_attacks support
- Instance values and attack activation across save/load
- Untrained fallback and attack-disable timing
- Lua movement, target, attack signatures, and turn handling
- Stable pursuit-target identification
- Melee effect damage requirements and monster downed, bleed, and SPEED behavior
- Compatibility with other dog overrides

## Open design questions

Training and UI, supported dog types, risk scores and transition thresholds, attack values/resistance/cooldowns, wound IDs and stacking, and detailed LURE phases/contact-breaking conditions remain undecided.

## Gameplay criteria

Dogs avoid group centers, withdraw before encirclement, support the player, and return safely. LURE separates an edge enemy and breaks pursuit before returning. Judge attacks by control and mobility-disruption value.

[Documentation index](index.md).
