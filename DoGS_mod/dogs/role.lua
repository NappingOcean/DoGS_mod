-- Per-dog role. Guard is the default (E6: vanilla-like free roaming ran the dog toward distant
-- enemies); "harass" and "free" must be chosen explicitly.
local config = require("dogs.config")
local breed = require("dogs.breed")
local debug_mode = require("dogs.debug")

local M = {}

---Harass is offered only when enabled (or in debug mode) and the dog's training reaches it.
---@param dog Monster
---@return boolean
function M.harass_allowed(dog)
  return (config.harass_enabled or debug_mode.on()) and breed.can(dog, "harass")
end

---@param dog Monster
---@return string "guard" | "harass" | "free"
function M.get(dog)
  local value = dog:get_value("dogs_role")
  if value == "harass" and M.harass_allowed(dog) then return value end
  return value == "free" and value or "guard"
end

---@param dog Monster
---@param value string "guard" | "harass" | "free"
function M.set(dog, value)
  dog:set_value("dogs_role", value)
end

return M
