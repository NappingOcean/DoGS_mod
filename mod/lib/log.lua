local M = {}
---@param event string
---@param text string
function M.write(event, text)
  gdebug.log_info("[DoGS] event=" .. event .. " " .. text)
end
---@param dog Monster
---@param action string
function M.transition(dog, action)
  if dog:get_value("dogs_action") ~= action then
    dog:set_value("dogs_action", action)
    M.write("action", "dog=" .. dog:get_type():str() .. " action=" .. action)
    if dog:get_value("dogs_messages") == "1" then
      gapi.add_msg(MsgType.info, "DoGS: " .. action)
    end
  end
end
return M
