# Training and integration

Prefer overriding vanilla dog types with **same-ID self copy-from** and assigning a shared `lua_ai` callback, rather than converting dogs into separate smart-dog types.

Add attacks through `extend.special_attacks`. Store training and AI state per instance.

## Callback responsibilities

- Untrained dogs: disable DoGS attacks and fall back to normal AI.
- Trained dogs: execute DoGS AI.
- Enable or disable only attack IDs added by DoGS.
- Preserve vanilla and other mods' special attacks.

## Reported technical findings — verify in BN

- `lua_ai` is a type-level JSON setting, not a callback assignable solely through runtime instance values.
- Special-attack enabled state is per instance and survives save/load.
- An initial attack JSON `enabled=false` field was not confirmed.

Manage DoGS attack activation in the callback. Verify untrained-dog behavior and save/load persistence.

Related: [Lua and movement](lua-and-movement.md), [Roadmap](roadmap.md).
