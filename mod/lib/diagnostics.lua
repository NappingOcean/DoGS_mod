local telemetry = require("lib.telemetry")
local config = require("lib.config")
local attacks = require("lib.attacks")
local M = {}
---@return integer
function M.open()
  local pos=gapi.look_around()
  if pos == nil then return 0 end
  local dog=gapi.get_monster_at(pos)
  if dog == nil then
    gapi.add_msg(MsgType.info,"DoGS: select a Labrador mutt (mon_dog).")
    return 0
  end
  if dog:get_type():str() ~= config.dog_id then
    telemetry.observe(dog,"menu_target",true)
    gapi.add_msg(MsgType.info,"DoGS: select a Labrador mutt to configure training.")
    return 0
  end
  local menu=UiList.new()
  menu:title("DoGS laboratory")
  menu:add(1,"Enable experimental training (friendly dog required)")
  menu:add(2,"Disable DoGS training")
  menu:add(3,"Show current dog status")
  menu:add(4,"Toggle action messages")
  menu:add(5,"Attack mode: automatic")
  menu:add(6,"Attack mode: Takedown only")
  menu:add(7,"Attack mode: Ankle Tear only")

  local choice=menu:query()
  local message=M.apply(dog,choice)
  if message then gapi.add_msg(MsgType.info,message) end
  return 0
end
---@param dog Monster
---@param choice integer
---@return string|nil
function M.apply(dog,choice)
  if choice == 1 then
    if dog.friendly == 0 then return "DoGS: tame the dog first." end
    dog:set_value("dogs_trained","1")
  elseif choice == 2 then dog:set_value("dogs_trained","0"); attacks.disable(dog)
  elseif choice == 4 then dog:set_value("dogs_messages",dog:get_value("dogs_messages") == "1" and "0" or "1")
  elseif choice >= 5 and choice <= 7 then dog:set_value("dogs_attack_mode",({"auto","takedown","ankle"})[choice-4])
  end
  if choice >= 1 and choice <= 7 then
    telemetry.observe(dog,"menu_change",true)
    return "DoGS: HP "..dog:get_hp().."/"..dog:get_hp_max()..", trained="..dog:get_value("dogs_trained")..", action="..dog:get_value("dogs_action")
  end
end
-- Keep old saved remote items usable; the action menu is the normal entry point.
---@param _who Character|nil
---@param _item Item|nil
---@param _pos TripointBubMs|nil
---@return integer
function M.remote(_who,_item,_pos) return M.open() end
return M
