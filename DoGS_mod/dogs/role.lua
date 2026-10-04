-- Per-dog role. Guard is the default (E6: vanilla-like free roaming ran the dog toward distant
-- enemies); only an explicit "free" opts out.
local M = {}

---@param dog Monster
---@return string "guard" | "free"
function M.get(dog)
  return dog:get_value("dogs_role") == "free" and "free" or "guard"
end

---@param dog Monster
function M.toggle(dog)
  dog:set_value("dogs_role", M.get(dog) == "guard" and "free" or "guard")
end

return M
