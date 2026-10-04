# Lua and movement

## Confirmed APIs

Creature exposes position, sight, attitude, effects/immunity, HP, speed, moves, and string instance values. Movement APIs are set_move_target(pos), set_target(creature), clear_move_target(), move_target(), run_normal_ai_turn(), and move_to(pos, force, step_on_critter, stagger_adjustment). The latter returns bool and handles actual step movement.

Special attacks expose has_special_attack, get_special_attack_ids, special_attack_ready, use_special_attack, special_attack_enabled, set_special_attack_enabled, and get/set_special_attack_cooldown. ready is not a prediction of range or hit; use returning true means an attempt was handled. DoGS must respect immunity, pacification, and action costs.

## Perception

Use gapi.get_all_monsters(), get_all_creatures(), get_monsters_if(filters), or tile lookup. Filters support sees, hostile_to, and within_range_of. They iterate active monsters, so evaluate their cost against local tile scans. sees={dog} asks whether the dog sees the candidate; LURE needs the opposite sight check too.

## Pursuit and movement limits

set_target snapshots a position; it does not retain identity. move_target is a destination, not proof of pursuit. No attack_target binding was found. Reacquire targets across actions and save/load.

Setting a waypoint does not execute movement. Returning true with no position/move change incurs a wait; run_normal_ai_turn replans and may replace the destination. Reuse existing movement where possible, but establish a tested waypoint execution strategy before LURE. Direct Lua movement must also honor movement-impairing effects.

## Callback contract

false/nil runs normal AI; true claims the action. Disable DoGS attacks before returning false for untrained dogs. If explicitly invoking run_normal_ai_turn, return true to prevent a second normal action.

Add minimal bindings only when these confirmed capabilities prove insufficient in play.

Source evidence and remaining runtime checks: [BN source verification](source-verification.md).
