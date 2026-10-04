local config = require("lib.config")
local policy = require("lib.policy")
local M = {}
---@param dog Monster
---@return Monster[]
function M.enemies(dog)
  local out = {}
  local avatar = gapi.get_avatar()
  for _, mon in ipairs(gapi.get_all_monsters()) do
    local pos = mon:get_pos_ms()
    if mon ~= dog and not mon:is_hallucination() and
      policy.distance(dog:get_pos_ms(), pos) <= config.radius and dog:sees(pos) and
      mon:attitude_to(avatar) == Attitude.Hostile and mon:attitude_to(dog) == Attitude.Hostile then
      out[#out+1] = mon
    end
  end
  return out
end
---@param pos TripointBubMs
---@param enemies Monster[]
---@param radius integer
---@return integer
function M.count(pos, enemies, radius)
  local n = 0
  for _, enemy in ipairs(enemies) do
    if policy.distance(pos, enemy:get_pos_ms()) <= radius then n=n+1 end
  end
  return n
end
---@param dog Monster
---@param enemies Monster[]
---@return Monster|nil
function M.target(dog, enemies)
  local best, score = nil, math.huge
  local avatar = gapi.get_avatar():get_pos_ms()
  for _, enemy in ipairs(enemies) do
    local pos = enemy:get_pos_ms()
    -- Penalize clustered candidates before considering range.
    local value = M.count(pos, enemies, 2)*4 + policy.distance(dog:get_pos_ms(),pos) + policy.distance(avatar,pos)*0.5
    if value < score then best, score = enemy, value end
  end
  return best
end
return M
