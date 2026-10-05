-- Per-dog role. Guard is the default (E6: vanilla-like free roaming ran the dog toward distant
-- enemies); "harass" and "free" must be chosen explicitly.
local M = {}

---@param dog Monster
local NEXT = { guard = "harass", harass = "free", free = "guard" }

---@return string "guard" | "harass" | "free"
function M.get(dog)
  local value = dog:get_value("dogs_role")
  return (value == "free" or value == "harass") and value or "guard"
end

---@param dog Monster
function M.toggle(dog)
  dog:set_value("dogs_role", NEXT[M.get(dog)])
end

return M
