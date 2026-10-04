# Training and integration

Prefer overriding vanilla dog types with **same-ID self copy-from** and assigning a shared `lua_ai` callback, rather than converting dogs into separate smart-dog types.

Add attacks through `extend.special_attacks`. Store training and AI state per instance.

## Callback responsibilities

- Untrained dogs: disable DoGS attacks and fall back to normal AI.
- Trained dogs: execute DoGS AI.
- Enable or disable only attack IDs added by DoGS.
- Preserve vanilla and other mods' special attacks.

## Confirmed integration constraints

lua_ai is type-level. Instance values are strings and persist across save/load. Attacks start enabled with randomized cooldown; the actor loader has no initial enabled field. Enabled state and cooldown persist in saves.

Disable only DoGS IDs in the callback, then return false for untrained fallback. If normal AI is invoked explicitly, return true afterward. Other mods may overwrite lua_ai or replace/clear attacks; load order must be tested with named combinations.

Related: [Lua and movement](lua-and-movement.md), [Roadmap](roadmap.md).

Source evidence and remaining runtime checks: [BN source verification](source-verification.md).
