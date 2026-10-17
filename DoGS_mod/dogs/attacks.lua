local config = require("dogs.config")
local policy = require("dogs.policy")
local breed = require("dogs.breed")
local debug_mode = require("dogs.debug")
local log = require("dogs.log")

local M = {}

local downed = EffectTypeId.new("downed")

---Takedown chance and downed turns for this dog on this target; nil chance when not worth trying.
---@param dog Monster
---@param target Monster
---@return integer|nil, integer|nil
local function takedown(dog, target)
  return policy.takedown(dog:get_weight():to_gram(), target:get_weight():to_gram(), breed.level(dog))
end

-- Set during one Takedown so on_dodged can tell a dodge from a hit.
local watch = nil
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
  if not breed.can(dog, "attacks") then return nil end
  return policy.choose_attack({
    mode = dog:get_value("dogs_attack_mode"),
    eligible = takedown(dog, target) ~= nil,
    downed = target:has_effect(downed),
    wounded = target:has_effect(ankle),
    flies = target:flies(),
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

---on_creature_dodged. Fires when a melee hit spread is <= 0; the actor counts exactly 0 as a hit,
---so that rare case is read as a miss (no knockdown).
---@param params table
function M.on_dodged(params)
  if watch == nil or params.char == nil or params.source == nil then return end
  local a, b = params.char:get_pos_ms(), watch.target
  local s, d = params.source:get_pos_ms(), watch.dog
  if a.x == b.x and a.y == b.y and a.z == b.z and s.x == d.x and s.y == d.y and s.z == d.z then
    watch.dodged = true
  end
end

---After a handled, undodged Takedown: knock down by weight ratio and training, regardless of damage dealt.
---@param dog Monster
---@param target Monster
---@param dodged boolean
---@return string outcome for the log
local function knock_down(dog, target, dodged)
  if dodged then return "dodged" end
  if target:is_dead_or_dying() then return "killed" end -- the blow itself was fatal (E7: #54)
  if target:is_immune_effect(downed) then return "immune" end
  local chance, turns = takedown(dog, target)
  if chance == nil or turns == nil then return "too_heavy" end -- forced or picked before the check
  local result = math.random(100) > chance and "resisted" or "knocked"
  if result == "knocked" then target:add_effect(downed, TimeDuration.from_turns(turns)) end
  return result .. " chance=" .. chance .. " turns=" .. turns
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
  watch = { dog = dog:get_pos_ms(), target = target:get_pos_ms(), dodged = false }
  local ok, handled = pcall(function() return dog:use_special_attack(id) end)
  local dodged = watch.dodged
  watch = nil
  M.disable(dog)
  if not ok then error(handled) end
  if not handled then return false end
  local outcome = id == "dogs_takedown" and knock_down(dog, target, dodged) or (dodged and "dodged" or "hit")

  dog:set_value("dogs_next_" .. id, tostring(now + config.attacks[id].cooldown))
  local damage = hp - target:get_hp()
  log.write("special", "dog=" .. log.id(dog) .. " target=" .. log.id(target) .. " target_type=" .. target:get_type():str() ..
    " id=" .. id .. " outcome=" .. outcome .. " damage=" .. damage .. " downed=" .. tostring(target:has_effect(downed)) ..
    " bleed=" .. tostring(target:has_effect(bleed)) .. " ankle=" .. tostring(target:has_effect(ankle)))
  if gapi.get_avatar():sees(dog:get_pos_ms()) then
    local who = debug_mode.on() and ("DoGS #" .. log.id(dog)) or ("Your " .. dog:name(1))
    gapi.add_msg(MsgType.info, string.format("%s: %s on %s (%s).", who, config.attacks[id].label,
      target:name(1), dodged and "dodged" or ((id == "dogs_takedown" and outcome:find("^knocked") and "knocked down, " or "") ..
        (damage > 0 and ("damage " .. damage) or "no damage"))))
  end
  return true
end

return M
