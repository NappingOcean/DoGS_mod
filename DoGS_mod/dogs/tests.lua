-- Pure policy checks run while loading. They prove the decision rules, not engine behavior.
local policy = require("dogs.policy")

local M = {}

local function p(x, y) return { x = x, y = y, z = 0 } end

local function obs(hp, adjacent, nearby, player, nearest, since_threat)
  if nearest == nil then nearest = adjacent > 0 and 1 or (nearby > 0 and 3 or math.huge) end
  if since_threat == nil then since_threat = nearest == math.huge and math.huge or 0 end
  return { hp = hp, adjacent = adjacent, nearby = nearby, player = player, nearest = nearest, since_threat = since_threat }
end

function M.run()
  -- Retreat entry and hold.
  assert(policy.next_state("", 0, obs(1, 2, 2, 1)) == "RETREAT")
  assert(policy.next_state("", 0, obs(1, 0, 4, 1)) == "RETREAT")
  assert(policy.next_state("", 0, obs(0.4, 1, 1, 1)) == "RETREAT")
  assert(policy.next_state("", 0, obs(0.4, 0, 0, 1)) == "DEFAULT")
  assert(policy.next_state("RETREAT", 1, obs(1, 0, 0, 1)) == "RETREAT")
  assert(policy.next_state("RETREAT", 2, obs(1, 0, 3, 1)) == "RETREAT")
  assert(policy.next_state("RETREAT", 2, obs(1, 0, 2, 1)) == "DEFAULT")

  -- Low HP: flee from an enemy within 5 tiles and stay out while any enemy is visible.
  assert(policy.next_state("", 0, obs(0.4, 0, 1, 1, 3)) == "RETREAT")
  assert(policy.next_state("", 0, obs(0.4, 0, 0, 1, 7)) == "DEFAULT")
  assert(policy.next_state("RETREAT", 5, obs(0.4, 0, 0, 1, 7)) == "RETREAT")
  assert(policy.next_state("RETREAT", 5, obs(0.4, 0, 0, 1)) == "DEFAULT")
  -- Object permanence: an enemy out of perception for under 5 turns still holds the retreat.
  assert(policy.next_state("RETREAT", 5, obs(0.4, 0, 0, 1, math.huge, 4)) == "RETREAT")
  assert(policy.next_state("RETREAT", 5, obs(0.4, 0, 0, 1, math.huge, 5)) == "DEFAULT")

  -- Regroup hysteresis: enter above 8, leave at 4 or closer after 3 turns.
  assert(policy.next_state("DEFAULT", 5, obs(1, 0, 0, 8)) == "DEFAULT")
  assert(policy.next_state("DEFAULT", 5, obs(1, 0, 0, 9)) == "REGROUP")
  assert(policy.next_state("REGROUP", 5, obs(1, 0, 0, 6)) == "REGROUP")
  assert(policy.next_state("REGROUP", 2, obs(1, 0, 0, 3)) == "REGROUP")
  assert(policy.next_state("REGROUP", 3, obs(1, 0, 0, 4)) == "DEFAULT")
  assert(policy.next_state("REGROUP", 5, obs(1, 2, 2, 9)) == "RETREAT")

  -- Control window and attack choice.
  assert(policy.control_window(obs(1, 1, 2, 1)))
  assert(not policy.control_window(obs(1, 1, 3, 1)))
  local both = { dogs_takedown = true, dogs_ankle_tear = true }
  local function ctx(mode, eligible, downed, wounded, ready)
    return { mode = mode, eligible = eligible, downed = downed, wounded = wounded, ready = ready }
  end
  assert(policy.choose_attack(ctx("", true, false, false, both)) == "dogs_takedown")
  assert(policy.choose_attack(ctx("", true, true, false, both)) == "dogs_ankle_tear")
  assert(policy.choose_attack(ctx("", true, true, true, both)) == nil)
  assert(policy.choose_attack(ctx("", false, false, false, both)) == "dogs_ankle_tear")
  assert(policy.choose_attack(ctx("takedown", false, false, false, both)) == nil)
  assert(policy.choose_attack(ctx("ankle", true, false, true, both)) == "dogs_ankle_tear")
  assert(policy.choose_attack(ctx("auto", true, false, false, { dogs_ankle_tear = true })) == "dogs_ankle_tear")

  -- Step ranking.
  local zombie = { p(1, 0) }
  local retreat = policy.rank_steps("retreat", p(0, 0), { p(-1, 0), p(1, 1), p(0, 1) }, zombie, p(-5, 0))
  assert(retreat[1].x == -1 and #retreat == 1)
  local flee = policy.rank_steps("flee", p(0, 0), { p(-1, 0), p(0, 1) }, zombie, p(-5, 0))
  assert(#flee == 1 and flee[1].x == -1)
  local safe = policy.behind_player(p(0, 0), { p(3, 0) }, p(-2, 0))
  assert(safe.x == -4 and safe.y == 0)
  assert(#policy.rank_steps("flee", p(-4, 0), { p(-5, 0), p(-3, 0), p(-4, 1) }, { p(3, 0) }, p(-2, 0)) == 0)
  local off = policy.rank_steps("disengage", p(0, 0), { p(-1, 0), p(0, 1), p(-1, -1) }, zombie, p(0, 5))
  assert(#off == 2 and off[1].x == -1 and off[1].y == 0)
  local back = policy.rank_steps("regroup", p(0, 0), { p(1, 1), p(-1, 0), p(0, 1) }, { p(3, 3) }, p(0, 5))
  -- (1,1) and (0,1) both close to 4 tiles; (0,1) stays farther from the enemy.
  assert(#back == 2 and back[1].x == 0 and back[1].y == 1)
  assert(#policy.rank_steps("regroup", p(0, 0), { p(1, 0) }, { p(2, 0) }, p(5, 0)) == 0)

  -- Guard: threats near the player or the dog; the one closest to the player first.
  local t = policy.guard_target(p(0, 0), { p(9, 9), p(3, 0), p(0, 5) }, p(0, 4))
  assert(t.x == 0 and t.y == 5)
  assert(policy.guard_target(p(0, 0), { p(9, 9) }, p(0, 4)) == nil)
  assert(policy.guard_target(p(0, 0), { p(2, 0) }, p(0, -6)).x == 2)
  -- Intercept closes on the goal but never leaves 3 tiles of the player.
  local go = policy.rank_steps("intercept", p(0, 0), { p(1, 0), p(-1, 0) }, { p(3, 0) }, p(-2, 0), p(3, 0))
  assert(#go == 1 and go[1].x == 1)
  -- At the edge of the radius, a step toward the goal that leaves 3 tiles is refused.
  assert(#policy.rank_steps("intercept", p(0, 0), { p(1, 0), p(0, 1) }, { p(3, 0) }, p(-3, 0), p(3, 0)) == 0)

  gdebug.log_info("[DoGS] event=selftest scope=policy result=pass")
end

return M
