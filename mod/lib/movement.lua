local telemetry = require("lib.telemetry")
local config = require("lib.config")
local policy = require("lib.policy")
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
---@param engage boolean|nil
---@return boolean
function M.step(dog, goal, enemies, retreat, engage)
  local origin = dog:get_pos_ms()
  if origin.z ~= goal.z then return false end
  local candidates = {}
  -- Freeze the threat set for this decision; live position reads must not change scores mid-step.
  local enemy_positions={}
  for _,enemy in ipairs(enemies) do enemy_positions[#enemy_positions+1]=enemy:get_pos_ms() end
  local function count(pos,radius)
    local n=0
    for _,ep in ipairs(enemy_positions) do if policy.distance(pos,ep)<=radius then n=n+1 end end
    return n
  end
  local function nearest(pos)
    local n=9
    for _,ep in ipairs(enemy_positions) do n=math.min(n,policy.distance(pos,ep)) end
    return n
  end
  for dx=-1,1 do for dy=-1,1 do
    if dx ~= 0 or dy ~= 0 then
      local pos = TripointBubMs.new(origin.x+dx,origin.y+dy,origin.z)
      if not gapi.get_map():is_out_of_bounds(pos) and gapi.get_creature_at(pos, true) == nil then
        local risk = count(pos,1)*20 + count(pos,2)*4
        local score = risk + policy.distance(pos,goal)
        if retreat then
          local nearest = 9
          for _, ep in ipairs(enemy_positions) do nearest=math.min(nearest,policy.distance(pos,ep)) end
          score = score - nearest*6
        end
        candidates[#candidates+1] = {pos=pos,score=score,risk=risk}
      end
    end
  end end
  table.sort(candidates,function(a,b) return a.score < b.score end)
  for _, candidate in ipairs(candidates) do
    local current_risk=count(origin,1)*20+count(origin,2)*4
    local improves=policy.accept_step(retreat,current_risk,candidate.risk,policy.distance(origin,goal),
      policy.distance(candidate.pos,goal),current_risk+policy.distance(origin,goal)-nearest(origin)*6,
      candidate.score,count(candidate.pos,1),count(candidate.pos,3),engage)
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
