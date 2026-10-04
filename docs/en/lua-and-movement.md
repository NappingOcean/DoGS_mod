# Lua and movement

The following capabilities and limitations were reported in the design discussion. Recheck them in the target BN version.

## Reported capabilities

| Area | Functions or information |
|---|---|
| Creature | Position, sight, effects, HP, speed |
| Movement / targets | `set_move_target`, `set_target`, `clear_move_target`, `move_to` |
| Normal AI fallback | `run_normal_ai_turn` |
| Special attacks | Lookup, enable/disable, cooldown, use |
| Instance state | `set_value`, `get_value` |
| Local perception | Map-tile scans and creature lookup |

Verify exposed types, arguments, return values, turn processing, and action costs.

## Limitations

A convenience API such as `get_visible_enemies()` and an exact current-pursuit-target getter were not confirmed. Consider local tile scans for perception. If stable pursuit identification across turns is impossible, consider minimal additional Lua bindings.

## Movement direction

Reuse monster movement/pathfinding where possible; Lua selects goals and waypoints rather than implementing complex detours itself. LURE needs pursuit breaking and a safe return detour, so validate the existing movement behavior in play.

Add only bindings justified by observed gameplay needs.

Related: [Risk](risk-and-positioning.md), [LURE](lure.md), [Integration](training-and-integration.md).
