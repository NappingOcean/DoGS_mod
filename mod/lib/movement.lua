local telemetry = require("lib.telemetry")
local config = require("lib.config")
local policy = require("lib.policy")
local perception = require("lib.perception")
local log = require("lib.log")
local M = {}
---@param dog Monster
---@return boolean
function M.blocked(dog)
  for _, id in ipairs(config.blockers) do
    if dog:has_effect(EffectTypeId.new(id)) then return true end
  end
  return dog:is_hallucination()
end
---@param dog Monster
---@param goal TripointBubMs
---@param enemies Monster[]
---@param retreat boolean
---@return boolean
function M.step(dog, goal, enemies, retreat)
  local origin = dog:get_pos_ms()
  if origin.z ~= goal.z then return false end
  local candidates = {}
  for dx=-1,1 do for dy=-1,1 do
    if dx ~= 0 or dy ~= 0 then
      local pos = TripointBubMs.new(origin.x+dx,origin.y+dy,origin.z)
      if not gapi.get_map():is_out_of_bounds(pos) and gapi.get_creature_at(pos, true) == nil then
        local risk = perception.count(pos,enemies,1)*20 + perception.count(pos,enemies,2)*4
        local score = risk + policy.distance(pos,goal)
        if retreat then
          local nearest = 9
          for _, enemy in ipairs(enemies) do nearest=math.min(nearest,policy.distance(pos,enemy:get_pos_ms())) end
          score = score - nearest*6
        end
        candidates[#candidates+1] = {pos=pos,score=score,risk=risk}
      end
    end
  end end
  table.sort(candidates,function(a,b) return a.score < b.score end)
  for _, candidate in ipairs(candidates) do
    local current_risk = perception.count(origin,enemies,1)*20 + perception.count(origin,enemies,2)*4
    local current_nearest = 9
    for _, enemy in ipairs(enemies) do current_nearest=math.min(current_nearest,policy.distance(origin,enemy:get_pos_ms())) end
    local improves = retreat and candidate.risk <= current_risk and candidate.score < current_risk + policy.distance(origin,goal) - current_nearest*6
      or (not retreat and policy.distance(candidate.pos,goal) < policy.distance(origin,goal) and candidate.risk <= current_risk)
    if improves then
      local moves=dog:get_moves()
      if dog:move_to(candidate.pos,false,false,1.0) then
        do
          log.write("move", "entity="..telemetry.id(dog).." from="..origin.x..","..origin.y..","..origin.z..
            " to="..candidate.pos.x..","..candidate.pos.y..","..candidate.pos.z..
            " cost="..tostring(moves-dog:get_moves()).." retreat="..tostring(retreat))
        end
        return true
      end
      -- A failed native move may still spend moves; never stack another action.
      if dog:get_moves() ~= moves then return true end
    end
  end
  log.write("move_blocked","entity="..telemetry.id(dog).." retreat="..tostring(retreat).." candidates="..#candidates)
  return false
end
return M
