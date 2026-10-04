local config = require("lib.config")
local M = {}
---@param a TripointBubMs
---@param b TripointBubMs
---@return number
function M.distance(a, b)
  if a.z ~= b.z then return math.huge end
  return math.max(math.abs(a.x-b.x), math.abs(a.y-b.y))
end
---@param hp number
---@param adjacent integer
---@param nearby integer
---@param player_distance number
---@param target_distance number|nil
---@param target_player_distance number|nil
---@return string
function M.choose(hp, adjacent, nearby, player_distance, target_distance, target_player_distance)
  if hp <= config.hp_retreat or adjacent >= config.adjacent_retreat or nearby >= config.nearby_retreat then return "RETREAT" end
  if player_distance > config.leash or target_distance == nil then return "REGROUP" end
  if target_player_distance <= 1 then return "ASSIST" end
  if target_player_distance <= 3 then return "INTERCEPT" end
  return "SKIRMISH"
end
return M
