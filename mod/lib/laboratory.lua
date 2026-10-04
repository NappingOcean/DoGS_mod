local log=require("lib.log")
local M={}
---@param dog Monster
function M.prepare(dog)
  if dog:get_value("dogs_lab_hp_version") ~= "1" and dog:get_hp_max() >= 3000 then
    dog:set_hp(dog:get_hp_max())
    dog:set_value("dogs_lab_hp_version","1")
    log.write("lab_hp","hp="..dog:get_hp().." max_hp="..dog:get_hp_max())
  end
end
return M
