local config = require("lib.config")
local attacks = require("lib.attacks")
local log = require("lib.log")
local M = {}
---@param dog Monster
function M.snapshot(dog)
  log.write("effects", "target="..dog:get_type():str().." speed="..dog:get_speed()..
    " downed="..tostring(dog:has_effect(EffectTypeId.new("downed")))..
    " bleed="..tostring(dog:has_effect(EffectTypeId.new("bleed")))..
    " ankle="..tostring(dog:has_effect(EffectTypeId.new("dogs_ankle_wound")))..
    " bleed_immune="..tostring(dog:is_immune_effect(EffectTypeId.new("bleed"))))
  log.write("snapshot","dog="..dog:get_type():str().." trained="..dog:get_value("dogs_trained")..
    " action="..dog:get_value("dogs_action").." hp="..dog:get_hp().." moves="..dog:get_moves())
  for _, id in ipairs(config.attacks) do
    log.write("cooldown","id="..id.." enabled="..tostring(dog:special_attack_enabled(id)).." turns="..tostring(dog:get_special_attack_cooldown(id)))
  end
end
---@param _who Character|nil
---@param _item Item|nil
---@param _pos TripointBubMs|nil
---@return integer
function M.remote(_who,_item,_pos)
  local pos=gapi.look_around()
  if pos == nil then return 0 end
  local dog=gapi.get_monster_at(pos)
  if dog == nil then
    gapi.add_msg(MsgType.info,"DoGS: select a Labrador mutt (mon_dog).")
    return 0
  end
  if dog:get_type():str() ~= config.dog_id then
    M.snapshot(dog)
    gapi.add_msg(MsgType.info,"DoGS: target effects written to debug.log.")
    return 0
  end
  local menu=UiList.new()
  menu:title("DoGS laboratory")
  menu:add(1,"Enable experimental training (friendly dog required)")
  menu:add(2,"Disable DoGS training")
  menu:add(3,"Write snapshot to debug.log")
  menu:add(4,"Toggle action messages")
  menu:add(5,"Attack mode: automatic")
  menu:add(6,"Attack mode: Takedown only")
  menu:add(7,"Attack mode: Ankle Tear only")
  menu:add(8,"Toggle detailed movement logs")
  local choice=menu:query()
  if choice == 1 then
    if dog.friendly == 0 then gapi.add_msg(MsgType.info,"DoGS: tame the dog first."); return 0 end
    dog:set_value("dogs_trained","1")
  elseif choice == 2 then dog:set_value("dogs_trained","0"); attacks.disable(dog)
  elseif choice == 4 then dog:set_value("dogs_messages",dog:get_value("dogs_messages") == "1" and "0" or "1")
  elseif choice == 8 then dog:set_value("dogs_trace",dog:get_value("dogs_trace") == "1" and "0" or "1")
  elseif choice >= 5 and choice <= 7 then dog:set_value("dogs_attack_mode",({"auto","takedown","ankle"})[choice-4])
  end
  if choice >= 1 and choice <= 8 then M.snapshot(dog); gapi.add_msg(MsgType.info,"DoGS: snapshot written to debug.log.") end
  return 0
end
return M
