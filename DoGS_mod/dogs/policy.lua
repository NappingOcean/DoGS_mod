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
---@field ready table<string, boolean>

---@param ctx DogsAttackContext
---@return string|nil attack id; nil leaves the turn to the stock AI
function M.choose_attack(ctx)
  local takedown = ctx.ready.dogs_takedown and ctx.eligible and not ctx.downed
  if ctx.mode == "takedown" then return takedown and "dogs_takedown" or nil end
  if ctx.mode == "ankle" then return ctx.ready.dogs_ankle_tear and "dogs_ankle_tear" or nil end
  if takedown then return "dogs_takedown" end
  if ctx.ready.dogs_ankle_tear and not ctx.wounded then return "dogs_ankle_tear" end
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

---Orders candidate tiles for a step; returns only acceptable ones, best first.
---kind: "retreat" lowers risk (ties broken toward the player),
---"flee" heads for the point behind the player without touching an enemy
---(from an adjacent start, any step that breaks contact is accepted),
---"disengage" leaves every enemy's reach, "regroup" closes on the player without new contact.
---@param kind string
---@param origin {x:integer,y:integer,z:integer}
---@param candidates {x:integer,y:integer,z:integer}[] free neighbor tiles
---@param enemies {x:integer,y:integer,z:integer}[]
---@param player {x:integer,y:integer,z:integer}
---@return {x:integer,y:integer,z:integer}[]
function M.rank_steps(kind, origin, candidates, enemies, player)
  local here_risk = M.risk(origin, enemies)
  local here_player = M.distance(origin, player)
  local here_adjacent = M.adjacent(origin, enemies)
  local safe = M.behind_player(origin, enemies, player)
  local here_safe = M.distance(origin, safe)
  local out = {}
  for _, c in ipairs(candidates) do
    local risk, to_player, nearest = M.risk(c, enemies), M.distance(c, player), M.nearest(c, enemies)
    local to_safe = M.distance(c, safe)
    local ok
    if kind == "retreat" then
      ok = risk < here_risk or (risk == here_risk and here_risk > 0 and to_player < here_player)
    elseif kind == "flee" then
      ok = M.adjacent(c, enemies) == 0 and (to_safe < here_safe or here_adjacent > 0)
    elseif kind == "disengage" then
      ok = M.adjacent(c, enemies) == 0
    else
      ok = to_player < here_player and M.adjacent(c, enemies) <= here_adjacent
    end
    if ok then out[#out + 1] = { pos = c, risk = risk, to_player = to_player, nearest = nearest, to_safe = to_safe } end
  end
  table.sort(out, function(a, b)
    if kind == "regroup" and a.to_player ~= b.to_player then return a.to_player < b.to_player end
    if kind == "flee" and a.to_safe ~= b.to_safe then return a.to_safe < b.to_safe end
    if kind == "flee" and a.nearest ~= b.nearest then return a.nearest > b.nearest end
    if a.risk ~= b.risk then return a.risk < b.risk end
    return a.to_player < b.to_player
  end)
  for i, row in ipairs(out) do out[i] = row.pos end
  return out
end

return M
