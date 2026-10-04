local config = require("dogs.config")
local policy = require("dogs.policy")
local log = require("dogs.log")

local M = {}

local downed = EffectTypeId.new("downed")
local bleed = EffectTypeId.new("bleed")
local ankle = EffectTypeId.new("dogs_ankle_wound")

---DoGS attacks stay disabled outside explicit use, so the stock scheduler never picks them.
---@param dog Monster
function M.disable(dog)
  for _, id in ipairs(config.attack_ids) do dog:set_special_attack_enabled(id, false) end
end

---@param dog Monster
---@param id string
---@param now integer
---@return boolean
local function ready(dog, id, now)
  return dog:has_special_attack(id) and (tonumber(dog:get_value("dogs_next_" .. id)) or 0) <= now
end

---@param dog Monster
---@param target Monster
---@param now integer
---@return string|nil
function M.choose(dog, target, now)
  return policy.choose_attack({
    mode = dog:get_value("dogs_attack_mode"),
    eligible = config.takedown_targets[target:get_type():str()] == true,
    downed = target:has_effect(downed),
    wounded = target:has_effect(ankle),
    ready = { dogs_takedown = ready(dog, "dogs_takedown", now), dogs_ankle_tear = ready(dog, "dogs_ankle_tear", now) },
  })
end

---Remaining DoGS cooldown in turns, for display.
---@param dog Monster
---@param id string
---@return integer
function M.remaining(dog, id)
  local next_turn = tonumber(dog:get_value("dogs_next_" .. id)) or 0
  return math.max(0, next_turn - gapi.current_turn():to_turn())
end

---@param dog Monster
---@param target Monster
---@param id string
---@param now integer
---@return boolean handled
function M.use(dog, target, id, now)
  local hp = target:get_hp()
  dog:set_target(target)
  dog:set_special_attack_enabled(id, true)
  dog:set_special_attack_cooldown(id, 0)
  local ok, handled = pcall(function() return dog:use_special_attack(id) end)
  M.disable(dog)
  if not ok then error(handled) end
  if not handled then return false end

  dog:set_value("dogs_next_" .. id, tostring(now + config.attacks[id].cooldown))
  local damage = hp - target:get_hp()
  log.write("special", "dog=" .. log.id(dog) .. " target=" .. log.id(target) .. " target_type=" .. target:get_type():str() ..
    " id=" .. id .. " damage=" .. damage .. " downed=" .. tostring(target:has_effect(downed)) ..
    " bleed=" .. tostring(target:has_effect(bleed)) .. " ankle=" .. tostring(target:has_effect(ankle)))
  if gapi.get_avatar():sees(dog:get_pos_ms()) then
    gapi.add_msg(MsgType.info, string.format("DoGS #%s: %s on %s (%s).", log.id(dog), config.attacks[id].label,
      target:name(1), damage > 0 and ("damage " .. damage) or "no damage: missed or stopped by armor"))
  end
  return true
end

return M
