-- Which monsters are DoGS dogs, and the BN training level that opens their capabilities.
local config = require("dogs.config")
local debug_mode = require("dogs.debug")

local M = {}

---@param mon Monster
---@return boolean
function M.is_dog(mon)
  return config.dog_ids[mon:get_type():str()] == true and not mon:is_hallucination()
end

---BN training_level. In debug mode the experiment menu can override it for tests.
---@param dog Monster
---@return integer
function M.level(dog)
  local override = tonumber(dog:get_value("dogs_debug_level"))
  if override and debug_mode.on() then return override end
  return dog.training_level
end

---@param dog Monster
---@param capability string key of config.training
---@return boolean
function M.can(dog, capability)
  return M.level(dog) >= config.training[capability]
end

return M
