local spacing=require("lib.spacing")
local laboratory=require("lib.laboratory")
local config = require("lib.config")
local policy = require("lib.policy")
local perception = require("lib.perception")
local movement = require("lib.movement")
local attacks = require("lib.attacks")
local log = require("lib.log")
local M = {}
---@param dog Monster
---@return boolean
function M.turn(dog)
  -- Disable DoGS actors before every fallback so stock AI cannot select them.
  attacks.disable(dog)
  if dog:get_type():str() ~= config.dog_id or dog:get_value("dogs_trained") ~= "1" or dog.friendly == 0 then return false end
  if movement.blocked(dog) then log.transition(dog,"BLOCKED"); return false end
  laboratory.prepare(dog)
  attacks.tick(dog,gapi.current_turn():to_turn())
  local enemies = perception.enemies(dog)
  spacing.observe(dog,enemies)
  local target = perception.target(dog,enemies)
  local pos = dog:get_pos_ms()
  local avatar = gapi.get_avatar():get_pos_ms()
  local action = policy.choose(dog:get_hp()/math.max(1,dog:get_hp_max()), perception.count(pos,enemies,1),
    perception.count(pos,enemies,3), policy.distance(pos,avatar),
    target and policy.distance(pos,target:get_pos_ms()), target and policy.distance(avatar,target:get_pos_ms()))
  if target and action~="RETREAT" and action~="RECOVER" and attacks.ready(dog,target)==nil then
    action="COOL_OFF"
  end
  log.transition(dog,action)
  dog:set_value("dog_mission","NORMAL")
  if action == "COOL_OFF" then
    if not spacing.safe(dog,enemies) then
      if movement.step(dog,avatar,enemies,true,false,true) then return true end
    end
    dog:mod_moves(-100)
    return true
  end
  if action == "RECOVER" then
    if policy.distance(pos,avatar)>2 then
      if movement.step(dog,avatar,enemies,false) then return true end
    end
    dog:mod_moves(-100)
    return true
  end
  if action == "RETREAT" then
    if not movement.step(dog,avatar,enemies,true,false,true) then dog:mod_moves(-100) end
    return true
  end
  if action == "REGROUP" then
    if policy.distance(pos,avatar) <= 2 then dog:mod_moves(-100); return true end
    if movement.step(dog,avatar,enemies,false) then return true end
    dog:mod_moves(-100)
    return true
  end
  if policy.distance(pos,target:get_pos_ms()) <= 1 then
    if attacks.try(dog,target) then return true end
    -- No uncontrolled stock engagement after a failed custom attack.
    dog:mod_moves(-100)
    return true
  end
  if movement.step(dog,target:get_pos_ms(),enemies,false,true) then return true end
  dog:mod_moves(-100)
  return true
end
return M
