local telemetry = require("lib.telemetry")
local config = require("lib.config")
local log = require("lib.log")
local M = {}
---@param dog Monster
function M.disable(dog)
  for _, id in ipairs(config.attacks) do dog:set_special_attack_enabled(id,false) end
end
-- Own actors stay disabled outside explicit use; BN does not tick disabled cooldowns.
---@param dog Monster
---@param now integer
function M.tick(dog,now)
  local previous=tonumber(dog:get_value("dogs_cooldown_turn")) or now
  local elapsed=math.max(0,now-previous)
  for _,id in ipairs(config.attacks) do
    local remaining=dog:get_special_attack_cooldown(id)
    if remaining ~= nil then dog:set_special_attack_cooldown(id,math.max(0,remaining-elapsed)) end
  end
  dog:set_value("dogs_cooldown_turn",tostring(now))
end
---@param dog Monster
---@param target Monster
---@return string|nil
function M.ready(dog,target)
  local mode=dog:get_value("dogs_attack_mode")
  local eligible=target:get_type():str()=="mon_zombie"
  local ids={}
  if mode=="takedown" then
    if eligible then ids={"dogs_takedown"} end
  elseif mode=="ankle" then ids={"dogs_ankle_tear"}
  elseif eligible and not target:has_effect(EffectTypeId.new("downed")) then
    ids={"dogs_takedown","dogs_ankle_tear"}
  else
    ids={"dogs_ankle_tear"}
    if eligible then ids[#ids+1]="dogs_takedown" end
  end
  for _,id in ipairs(ids) do
    if dog:has_special_attack(id) and dog:get_special_attack_cooldown(id)==0 then return id end
  end
  return nil
end
---@param id string
---@param damage number
---@return string
function M.message(id,damage)
  local label=id=="dogs_takedown" and "Takedown" or "Ankle Tear"
  return "uses "..label.." (damage "..damage..(damage==0 and "; missed or stopped by armor" or "")..")"
end
---@param dog Monster
---@param target Monster
---@return boolean
function M.try(dog,target)
  local id=M.ready(dog,target)
  if id==nil then return false end
  telemetry.observe(target,"before_attack")
  dog:set_target(target)
  dog:set_special_attack_enabled(id,true)
  local ready = dog:special_attack_ready(id)
  local hp = target:get_hp()
  local ok, handled = true, false
  if ready then ok, handled = pcall(function() return dog:use_special_attack(id) end) end
  M.disable(dog)
  if not ok then error(handled) end
  if ready then
    log.write("attack", "entity="..telemetry.id(dog).." target_entity="..telemetry.id(target).." id="..id.." target="..target:get_type():str().." handled="..tostring(handled)..
      " damage="..tostring(hp-target:get_hp()).." downed="..tostring(target:has_effect(EffectTypeId.new("downed")))..
      " bleed="..tostring(target:has_effect(EffectTypeId.new("bleed")))..
      " ankle="..tostring(target:has_effect(EffectTypeId.new("dogs_ankle_wound")))..
      " cooldown="..tostring(dog:get_special_attack_cooldown(id)))
  end
  if handled and gapi.get_avatar():sees(dog:get_pos_ms()) then
    local damage=hp-target:get_hp()
    gapi.add_msg(MsgType.info,"DoGS: dog #"..telemetry.id(dog).." "..M.message(id,damage).." on "..target:name(1)..
      "; downed="..tostring(target:has_effect(EffectTypeId.new("downed")))..
      ", ankle wound="..tostring(target:has_effect(EffectTypeId.new("dogs_ankle_wound")))..".")
  end
  telemetry.observe(target,"after_attack")
  return handled
end
return M
