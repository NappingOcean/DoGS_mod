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
  if hp <= config.hp_retreat or adjacent >= config.adjacent_retreat or nearby >= config.nearby_retreat then
    if hp <= config.hp_retreat and adjacent == 0 and nearby == 0 then return "RECOVER" end
    return "RETREAT"
  end
  if player_distance > config.leash or target_distance == nil then return "REGROUP" end
  if target_player_distance <= 1 then return "ASSIST" end
  if target_player_distance <= 3 then return "INTERCEPT" end
  return "SKIRMISH"
end
---@param retreat boolean
---@param current_risk number
---@param candidate_risk number
---@param current_distance number
---@param candidate_distance number
---@param current_score number
---@param candidate_score number
---@param adjacent integer
---@param nearby integer
---@param engage boolean|nil
---@return boolean
function M.accept_step(retreat,current_risk,candidate_risk,current_distance,candidate_distance,current_score,candidate_score,adjacent,nearby,engage)
  if retreat then return candidate_risk<=current_risk and candidate_score<current_score end
  local safe_entry=engage and adjacent<=1 and nearby<config.nearby_retreat
  return candidate_distance<current_distance and (candidate_risk<=current_risk or safe_entry) or false
end
return M
