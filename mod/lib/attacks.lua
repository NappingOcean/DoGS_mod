local config = require("lib.config")
local log = require("lib.log")
local M = {}
---@param dog Monster
function M.disable(dog)
  for _, id in ipairs(config.attacks) do dog:set_special_attack_enabled(id,false) end
end
---@param dog Monster
---@param target Monster
---@return boolean
function M.try(dog,target)
  -- Experimental eligibility: only the ordinary zombie, not all flesh targets.
  local id = "dogs_ankle_tear"
  local mode = dog:get_value("dogs_attack_mode")
  if mode == "takedown" or (mode ~= "ankle" and not target:has_effect(EffectTypeId.new("downed"))) then id="dogs_takedown" end
  if id == "dogs_takedown" and target:get_type():str() ~= "mon_zombie" then
    if mode == "takedown" then return false end
    id = "dogs_ankle_tear"
  end
  local telemetry=require("lib.telemetry")
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
  telemetry.observe(target,"after_attack")
  return handled
end
return M
