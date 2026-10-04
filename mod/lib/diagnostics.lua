local policy=require("lib.policy")
local telemetry = require("lib.telemetry")
local config = require("lib.config")
local attacks = require("lib.attacks")
local M = {}
---@return integer
function M.open()
  local avatar=gapi.get_avatar()
  local dogs={}
  for _,mon in ipairs(gapi.get_all_monsters()) do
    if mon:get_type():str()==config.dog_id and not mon:is_hallucination() and avatar:sees(mon:get_pos_ms()) then
      dogs[#dogs+1]={mon=mon,distance=policy.distance(avatar:get_pos_ms(),mon:get_pos_ms()),id=telemetry.id(mon)}
    end
  end
  table.sort(dogs,function(a,b)
    if a.distance==b.distance then return tonumber(a.id)<tonumber(b.id) end
    return a.distance<b.distance
  end)
  if #dogs==0 then gapi.add_msg(MsgType.info,"DoGS: no supported dogs in sight."); return 0 end
  local dog=dogs[1].mon
  if #dogs>1 then
    local selector=UiList.new()
    selector:title("DoGS - choose a dog")
    for index,row in ipairs(dogs) do
      local mon=row.mon
      selector:add(index,"#"..row.id.." "..mon:name(1).." | HP "..mon:get_hp().."/"..mon:get_hp_max()..
        " | "..row.distance.." tiles | "..(mon:get_value("dogs_trained")=="1" and "DoGS ON" or "DoGS OFF")..
        (mon.friendly==0 and " | untamed" or ""))
    end
    local selected=selector:query()
    if dogs[selected]==nil then return 0 end
    dog=dogs[selected].mon
  end
  local menu=UiList.new()
  menu:title("DoGS #"..telemetry.id(dog).." | "..(dog:get_value("dogs_trained")=="1" and "ON" or "OFF").." | HP "..dog:get_hp().."/"..dog:get_hp_max()..
    " | mode "..(dog:get_value("dogs_attack_mode")=="" and "auto" or dog:get_value("dogs_attack_mode")))
  menu:add(1,"Enable experimental training (friendly dog required)")
  menu:add(2,"Disable DoGS training")
  menu:add(3,"Show current dog status")
  menu:add(4,"Action messages: "..(dog:get_value("dogs_messages")=="1" and "ON" or "OFF").." (toggle)")
  menu:add(5,"Attack mode: automatic | Takedown CD "..tostring(dog:get_special_attack_cooldown("dogs_takedown")).." / Ankle Tear CD "..tostring(dog:get_special_attack_cooldown("dogs_ankle_tear")))
  menu:add(6,"Attack mode: Takedown only")
  menu:add(7,"Attack mode: Ankle Tear only")

  menu:add(8,"Refill experimental HP")
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
  elseif choice == 8 then dog:set_hp(dog:get_hp_max())
  elseif choice >= 5 and choice <= 7 then dog:set_value("dogs_attack_mode",({"auto","takedown","ankle"})[choice-4])
  end
  if choice >= 1 and choice <= 8 then
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
