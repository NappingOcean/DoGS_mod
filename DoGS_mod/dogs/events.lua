-- Observation for experiments. Covers trained and untrained dogs alike so E0 has a baseline.
local config = require("dogs.config")
local policy = require("dogs.policy")
local perception = require("dogs.perception")
local log = require("dogs.log")

local M = {}

local downed = EffectTypeId.new("downed")

---@param mon Monster
---@return boolean
local function is_dog(mon)
  return mon:get_type():str() == config.dog_id and not mon:is_hallucination()
end

---@param dog Monster
local function summarize(dog)
  local enemies = perception.enemies(dog)
  local enemy_hp = 0
  for _, enemy in ipairs(enemies) do enemy_hp = enemy_hp + enemy:get_hp() end
  local obs = perception.observe(dog, enemies)
  local pos = dog:get_pos_ms()
  log.write("summary", "dog=" .. log.id(dog) .. " trained=" .. (dog:get_value("dogs_trained") == "1" and "1" or "0") ..
    " role=" .. (dog:get_value("dogs_role") == "guard" and "guard" or "free") ..
    " state=" .. (dog:get_value("dogs_state") == "" and "none" or dog:get_value("dogs_state")) ..
    " pos=" .. pos.x .. "," .. pos.y .. " hp=" .. dog:get_hp() .. "/" .. dog:get_hp_max() ..
    " player=" .. tostring(obs.player) .. " adjacent=" .. obs.adjacent .. " nearby=" .. obs.nearby ..
    " enemies=" .. #enemies .. " enemy_hp=" .. enemy_hp .. " player_hp=" .. gapi.get_avatar():get_hp())
end

function M.summary()
  for _, mon in ipairs(gapi.get_all_monsters()) do
    if is_dog(mon) and mon.friendly ~= 0 then summarize(mon) end
  end
end

---Numbers the monster so later events (death, special) can be matched to it.
---@param mon Monster
---@return string
local function label(mon)
  return mon:get_type():str() .. "#" .. log.id(mon)
end

---Player-side melee near the fight (E6): the player's swings, with whether the target was downed,
---and enemy swings at the player, with the player's HP afterwards. Fired after the hit resolves.
---@param attacker Creature
---@param target Creature
---@param hit boolean
local function player_melee(attacker, target, hit)
  if attacker:is_avatar() and target:is_monster() then
    local mon = target:as_monster()
    log.write("player_melee", "target=" .. label(mon) .. " hit=" .. tostring(hit) ..
      " downed=" .. tostring(mon:has_effect(downed)) .. " target_hp=" .. mon:get_hp())
  elseif target:is_avatar() and attacker:is_monster() then
    log.write("player_attacked", "attacker=" .. label(attacker:as_monster()) .. " hit=" .. tostring(hit) ..
      " player_hp=" .. target:get_hp())
  end
end

---on_creature_melee_attacked: the stock monster/character melee path only.
---DoGS special attacks use the generic melee actor and are logged as "special" instead.
---@param params table
function M.on_melee(params)
  local attacker = params.char
  local target = params.target
  if attacker == nil or target == nil then return end
  player_melee(attacker, target, params.success)
  if not attacker:is_monster() then return end
  local dog = attacker:as_monster()
  if dog == nil or not is_dog(dog) or dog.friendly == 0 then return end
  local target_type = target:is_monster() and target:as_monster():get_type():str() or "character"
  log.write("melee", "dog=" .. log.id(dog) .. " target_type=" .. target_type .. " hit=" .. tostring(params.success) ..
    " target_hp=" .. target:get_hp() .. " distance=" .. policy.distance(dog:get_pos_ms(), target:get_pos_ms()))
end

---@param who Creature|nil
---@return string
local function describe(who)
  if who == nil then return "none" end
  if who:is_avatar() then return "avatar" end
  if who:is_monster() then
    local mon = who:as_monster()
    return mon:get_type():str() .. (mon:get_value("dogs_id") ~= "" and ("#" .. mon:get_value("dogs_id")) or "")
  end
  return "npc"
end

---on_mon_death: separates combat deaths from cleanup kills in experiment logs.
---Logged for dogs, kills by dogs, and creatures DoGS already numbered (attack targets).
---@param params table
function M.on_death(params)
  local mon = params.mon
  local killer = params.killer
  if mon == nil then return end
  local by_dog = killer ~= nil and killer:is_monster() and is_dog(killer:as_monster())
  if not is_dog(mon) and not by_dog and mon:get_value("dogs_id") == "" then return end
  log.write("death", "victim=" .. describe(mon) .. " killer=" .. describe(killer))
end

return M
