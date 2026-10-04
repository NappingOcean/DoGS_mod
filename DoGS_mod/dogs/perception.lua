local config = require("dogs.config")
local policy = require("dogs.policy")

local M = {}

---Visible monsters hostile to both the dog and the player, same z-level, within radius.
---Hostile NPCs are not considered yet.
---@param dog Monster
---@param radius number|nil defaults to config.radius; math.huge leaves only the sight check
---@return Monster[]
function M.enemies(dog, radius)
  radius = radius or config.radius
  local out = {}
  local here = dog:get_pos_ms()
  local avatar = gapi.get_avatar()
  for _, mon in ipairs(gapi.get_all_monsters()) do
    local pos = mon:get_pos_ms()
    if mon ~= dog and not mon:is_hallucination() and policy.distance(here, pos) <= radius
      and dog:sees(pos) and mon:attitude_to(dog) == Attitude.Hostile
      and mon:attitude_to(avatar) == Attitude.Hostile then
      out[#out + 1] = mon
    end
  end
  return out
end

---@param dog Monster
---@param enemies Monster[]
---@return DogsObservation, table[] positions frozen for this decision
function M.observe(dog, enemies)
  local here = dog:get_pos_ms()
  local positions = {}
  local adjacent, nearby, nearest = 0, 0, math.huge
  for i, enemy in ipairs(enemies) do
    local pos = enemy:get_pos_ms()
    positions[i] = pos
    local d = policy.distance(here, pos)
    if d <= 1 then adjacent = adjacent + 1 end
    if d <= 3 then nearby = nearby + 1 end
    nearest = math.min(nearest, d)
  end
  local obs = {
    hp = dog:get_hp() / math.max(1, dog:get_hp_max()),
    adjacent = adjacent,
    nearby = nearby,
    nearest = nearest,
    player = policy.distance(here, gapi.get_avatar():get_pos_ms()),
  }
  return obs, positions
end

---@param dog Monster
---@param enemies Monster[]
---@param effect EffectTypeId
---@return boolean
function M.adjacent_with(dog, enemies, effect)
  local here = dog:get_pos_ms()
  for _, enemy in ipairs(enemies) do
    if policy.distance(here, enemy:get_pos_ms()) <= 1 and enemy:has_effect(effect) then return true end
  end
  return false
end

---@param dog Monster
---@param enemies Monster[]
---@return Monster|nil
function M.adjacent_enemy(dog, enemies)
  local here = dog:get_pos_ms()
  for _, enemy in ipairs(enemies) do
    if policy.distance(here, enemy:get_pos_ms()) <= 1 then return enemy end
  end
  return nil
end

return M
