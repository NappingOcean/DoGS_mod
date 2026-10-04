local telemetry=require("lib.telemetry")
local policy=require("lib.policy")
local log=require("lib.log")
local M={}
local samples={}
local observed_attacks={}
---@param dog Monster
---@param target Monster
---@return integer
function M.reach(dog,target)
  return tonumber(dog:get_value("dogs_reach_"..target:get_type():str())) or 1
end
---@param dog Monster
---@param target Monster
---@param distance integer
---@param evidence string
function M.learn(dog,target,distance,evidence)
  if distance<=1 or distance==math.huge then return end
  local key="dogs_reach_"..target:get_type():str()
  local previous=M.reach(dog,target)
  if distance>previous then
    dog:set_value(key,tostring(distance))
    log.write("reach_learning","entity="..dog:get_value("dogs_debug_id").." target="..target:get_type():str()..
      " old="..previous.." reach="..distance.." evidence="..evidence)
  end
end
---@param dog Monster
---@param enemies Monster[]
function M.observe(dog,enemies)
  local id=dog:get_value("dogs_debug_id")
  local current={hp=dog:get_hp(),type=nil,distance=nil}
  if #enemies==1 then
    current.type=enemies[1]:get_type():str()
    current.enemy_id=telemetry.id(enemies[1])
    current.distance=policy.distance(dog:get_pos_ms(),enemies[1]:get_pos_ms())
  end
  local previous=samples[id]
  -- No general monster-damage/source hook is available. This is a cautious hypothesis,
  -- not proof of the damage source. Never attribute a crowd's damage to one target.
  if previous and not observed_attacks[id] and current.enemy_id==previous.enemy_id and current.hp<previous.hp and current.type and current.type==previous.type and
    previous.distance and previous.distance>1 and current.distance>1 and
    not dog:has_effect(EffectTypeId.new("bleed")) then
    M.learn(dog,enemies[1],math.min(previous.distance,current.distance),"suspected_nonadjacent_hp_loss")
  end
  observed_attacks[id]=nil
  samples[id]=current
end
---@param dog Monster
---@param enemies Monster[]
---@return boolean
function M.safe(dog,enemies)
  for _,enemy in ipairs(enemies) do
    if policy.distance(dog:get_pos_ms(),enemy:get_pos_ms())<=M.reach(dog,enemy) then return false end
  end
  return true
end
---@param params table
function M.on_melee(params)
  if not params.success or params.target == nil or params.char == nil or not params.target:is_monster() then return end
  local dog=gapi.get_monster_at(params.target:get_pos_ms())
  if dog == nil or dog:get_value("dogs_trained")~="1" or not params.char:is_monster() then return end
  observed_attacks[dog:get_value("dogs_debug_id")]=true
  local enemy=gapi.get_monster_at(params.char:get_pos_ms())
  if enemy then M.learn(dog,enemy,policy.distance(dog:get_pos_ms(),enemy:get_pos_ms()),"observed_successful_melee") end
end
return M
