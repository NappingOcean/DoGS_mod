-- Pure decision functions: plain numbers and tables in, no engine objects.
local config = require("dogs.config")

local M = {}

---Chebyshev tile distance; different z-levels are unreachable.
---@param a {x:integer,y:integer,z:integer}
---@param b {x:integer,y:integer,z:integer}
---@return number
function M.distance(a, b)
  if a.z ~= b.z then return math.huge end
  return math.max(math.abs(a.x - b.x), math.abs(a.y - b.y))
end

---@class DogsObservation
---@field hp number HP ratio 0..1
---@field adjacent integer enemies within 1 tile
---@field nearby integer enemies within 3 tiles
---@field player number distance to the player
---@field nearest number distance to the nearest visible enemy (math.huge if none)
---@field since_threat number turns since an enemy was last perceived (0 if one is now; math.huge if never)

---@param obs DogsObservation
---@return boolean
function M.low_hp(obs)
  return obs.hp <= config.retreat.hp
end

---Tactical state with hysteresis. "DEFAULT" means the stock AI leads.
---@param state string previous state ("" on first use)
---@param held integer turns spent in the previous state
---@param obs DogsObservation
---@return string
function M.next_state(state, held, obs)
  local r = config.retreat
  if obs.adjacent >= r.adjacent or obs.nearby >= r.nearby or (M.low_hp(obs) and obs.nearest <= r.flee) then
    return "RETREAT"
  end
  if state == "RETREAT" then
    -- Low HP: stay out while an enemy is perceived or was perceived within the memory window.
    if M.low_hp(obs) and obs.since_threat < r.memory then return "RETREAT" end
    if held < r.hold or obs.adjacent > 0 or obs.nearby > r.exit_nearby then return "RETREAT" end
  end
  local g = config.regroup
  if obs.player > g.enter then return "REGROUP" end
  if state == "REGROUP" and (held < g.hold or obs.player > g.exit) then return "REGROUP" end
  return "DEFAULT"
end

---A control attack needs a lone adjacent enemy.
---@param obs DogsObservation
---@return boolean
function M.control_window(obs)
  return obs.adjacent == 1 and obs.nearby <= config.control_nearby
end

---@class DogsAttackContext
---@field mode string "" / "auto", "takedown" or "ankle"
---@field eligible boolean target accepts Takedown
---@field downed boolean
---@field wounded boolean target already has dogs_ankle_wound
---@field flies boolean|nil target flies: no ankle to reach, but a Takedown can still knock it down
---@field ready table<string, boolean>

---Takedown chance in percent for a creature size name ("TINY" .. "HUGE").
---@param size string
---@return integer
function M.takedown_chance(size)
  return config.takedown.chance[size] or 0
end

---@param ctx DogsAttackContext
---@return string|nil attack id; nil leaves the turn to the stock AI
function M.choose_attack(ctx)
  local takedown = ctx.ready.dogs_takedown and ctx.eligible and not ctx.downed
  if ctx.mode == "takedown" then return takedown and "dogs_takedown" or nil end
  local ankle = ctx.ready.dogs_ankle_tear and not ctx.flies
  if ctx.mode == "ankle" then return ankle and "dogs_ankle_tear" or nil end
  if takedown then return "dogs_takedown" end
  if ankle and not ctx.wounded then return "dogs_ankle_tear" end
  return nil
end

---Tile danger: adjacent enemies dominate, enemies two tiles away add pressure.
---@param pos {x:integer,y:integer,z:integer}
---@param enemies {x:integer,y:integer,z:integer}[]
---@return integer
function M.risk(pos, enemies)
  local n = 0
  for _, e in ipairs(enemies) do
    local d = M.distance(pos, e)
    if d <= 1 then n = n + 10 elseif d <= 2 then n = n + 3 end
  end
  return n
end

---@param pos {x:integer,y:integer,z:integer}
---@param enemies {x:integer,y:integer,z:integer}[]
---@return integer
function M.adjacent(pos, enemies)
  local n = 0
  for _, e in ipairs(enemies) do
    if M.distance(pos, e) <= 1 then n = n + 1 end
  end
  return n
end

---@param pos {x:integer,y:integer,z:integer}
---@param enemies {x:integer,y:integer,z:integer}[]
---@return number
function M.nearest(pos, enemies)
  local n = math.huge
  for _, e in ipairs(enemies) do n = math.min(n, M.distance(pos, e)) end
  return n
end

---Fall-back point for a wounded dog: two tiles past the player, away from the enemy nearest the dog,
---so the player stands between the dog and its pursuer.
---@param dog {x:integer,y:integer,z:integer}
---@param enemies {x:integer,y:integer,z:integer}[]
---@param player {x:integer,y:integer,z:integer}
---@return {x:integer,y:integer,z:integer}
function M.behind_player(dog, enemies, player)
  local pursuer, best = nil, math.huge
  for _, e in ipairs(enemies) do
    local d = M.distance(dog, e)
    if d < best then pursuer, best = e, d end
  end
  if pursuer == nil then return player end
  local function sign(v) return v > 0 and 1 or (v < 0 and -1 or 0) end
  return { x = player.x + 2 * sign(player.x - pursuer.x), y = player.y + 2 * sign(player.y - pursuer.y), z = player.z }
end

---Guard role: the enemy to take on, if any. Threats are enemies within `engage` tiles of the
---player or of the dog; the one closest to the player comes first.
---@param dog {x:integer,y:integer,z:integer}
---@param enemies {x:integer,y:integer,z:integer}[]
---@param player {x:integer,y:integer,z:integer}
---@return {x:integer,y:integer,z:integer}|nil
function M.guard_target(dog, enemies, player)
  local engage = config.guard.engage
  local best, best_d = nil, math.huge
  for _, e in ipairs(enemies) do
    local to_player = M.distance(e, player)
    if (to_player <= engage or M.distance(e, dog) <= engage) and to_player < best_d then
      best, best_d = e, to_player
    end
  end
  return best
end

---Harass role: index of the enemy to hold up. Candidates are within harass.range of the player but
---not yet on the player, and exposed (at most harass.crowd others within 2 tiles). The current
---target is kept while it qualifies; otherwise the one closest to the player (next to arrive).
---@param enemies {x:integer,y:integer,z:integer}[]
---@param player {x:integer,y:integer,z:integer}
---@param current integer|nil index of the current target in `enemies`
---@return integer|nil
function M.harass_target(enemies, player, current)
  local h = config.harass
  local function ok(i)
    local e = enemies[i]
    local d = M.distance(e, player)
    if d <= 1 or d > h.range then return false end
    local crowd = 0
    for j, o in ipairs(enemies) do
      if j ~= i and M.distance(e, o) <= 2 then crowd = crowd + 1 end
    end
    return crowd <= h.crowd
  end
  if current and enemies[current] and ok(current) then return current end
  local best, best_d = nil, math.huge
  for i, e in ipairs(enemies) do
    local d = M.distance(e, player)
    if ok(i) and d < best_d then best, best_d = i, d end
  end
  return best
end

---Kite key: distance band to the target first (0 inside hold_min..hold_max), then risk, then
---preferring tiles farther from the player so the target is drawn away rather than toward it.
---@return number, number, number
local function kite_key(pos, goal, enemies, player)
  local h = config.harass
  local d = M.distance(pos, goal)
  local band = d < h.hold_min and (h.hold_min - d) or (d > h.hold_max and (d - h.hold_max) or 0)
  return band, M.risk(pos, enemies), -M.distance(pos, player)
end

---@return boolean
local function key_less(a1, a2, a3, b1, b2, b3)
  if a1 ~= b1 then return a1 < b1 end
  if a2 ~= b2 then return a2 < b2 end
  return a3 < b3
end

---Orders candidate tiles for a step; returns only acceptable ones, best first.
---kind: "retreat" lowers risk (ties broken toward the player),
---"flee" heads for the point behind the player without touching an enemy
---(from an adjacent start, any step that breaks contact is accepted),
---"disengage" leaves every enemy's reach, "regroup" closes on the player without new contact,
---"intercept" closes on `goal` without leaving `radius` around the player,
---"kite" keeps hold_min..hold_max tiles from `goal` without contact or leaving `radius`.
---@param kind string
---@param origin {x:integer,y:integer,z:integer}
---@param candidates {x:integer,y:integer,z:integer}[] free neighbor tiles
---@param enemies {x:integer,y:integer,z:integer}[]
---@param player {x:integer,y:integer,z:integer}
---@param goal {x:integer,y:integer,z:integer}|nil target tile for "intercept" and "kite"
---@param radius number|nil limit around the player for "intercept" and "kite" (default guard radius)
---@return {x:integer,y:integer,z:integer}[]
function M.rank_steps(kind, origin, candidates, enemies, player, goal, radius)
  radius = radius or config.guard.radius
  local here_risk = M.risk(origin, enemies)
  local here_player = M.distance(origin, player)
  local here_adjacent = M.adjacent(origin, enemies)
  local safe = M.behind_player(origin, enemies, player)
  local here_safe = M.distance(origin, safe)
  local out = {}
  for _, c in ipairs(candidates) do
    local risk, to_player, nearest = M.risk(c, enemies), M.distance(c, player), M.nearest(c, enemies)
    local to_safe = M.distance(c, safe)
    local to_goal = goal and M.distance(c, goal) or 0
    local ok
    if kind == "retreat" then
      ok = risk < here_risk or (risk == here_risk and here_risk > 0 and to_player < here_player)
    elseif kind == "flee" then
      ok = M.adjacent(c, enemies) == 0 and (to_safe < here_safe or here_adjacent > 0)
    elseif kind == "intercept" then
      ok = to_goal < M.distance(origin, goal) and to_player <= radius
    elseif kind == "kite" then
      local c1, c2, c3 = kite_key(c, goal, enemies, player)
      local o1, o2, o3 = kite_key(origin, goal, enemies, player)
      ok = M.adjacent(c, enemies) == 0 and to_player <= radius and key_less(c1, c2, c3, o1, o2, o3)
    elseif kind == "disengage" then
      ok = M.adjacent(c, enemies) == 0
    else
      ok = to_player < here_player and M.adjacent(c, enemies) <= here_adjacent
    end
    if ok then
      out[#out + 1] = { pos = c, risk = risk, to_player = to_player, nearest = nearest, to_safe = to_safe, to_goal = to_goal }
    end
  end
  table.sort(out, function(a, b)
    if kind == "regroup" and a.to_player ~= b.to_player then return a.to_player < b.to_player end
    if kind == "flee" and a.to_safe ~= b.to_safe then return a.to_safe < b.to_safe end
    if kind == "intercept" and a.to_goal ~= b.to_goal then return a.to_goal < b.to_goal end
    if kind == "kite" then
      local a1, a2, a3 = kite_key(a.pos, goal, enemies, player)
      local b1, b2, b3 = kite_key(b.pos, goal, enemies, player)
      if a1 ~= b1 or a2 ~= b2 or a3 ~= b3 then return key_less(a1, a2, a3, b1, b2, b3) end
    end
    if kind == "flee" and a.nearest ~= b.nearest then return a.nearest > b.nearest end
    if a.risk ~= b.risk then return a.risk < b.risk end
    return a.to_player < b.to_player
  end)
  for i, row in ipairs(out) do out[i] = row.pos end
  return out
end

return M
