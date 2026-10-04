local config = require("dogs.config")
local policy = require("dogs.policy")
local attacks = require("dogs.attacks")
local log = require("dogs.log")
local roles = require("dogs.role")

local M = {}

local MODES = { "auto", "takedown", "ankle" }

local role = roles.get

---@param dog Monster
---@param key string
---@return boolean
local function on(dog, key) return dog:get_value(key) == "1" end

---@param dog Monster
---@param key string
local function toggle(dog, key) dog:set_value(key, on(dog, key) and "" or "1") end

-- State messages default to on, so only an explicit "0" silences them.
---@param dog Monster
---@return boolean
local function messages_on(dog) return dog:get_value("dogs_messages") ~= "0" end

---@return Monster|nil
local function pick_dog()
  local avatar = gapi.get_avatar()
  local here = avatar:get_pos_ms()
  local dogs = {}
  for _, mon in ipairs(gapi.get_all_monsters()) do
    if mon:get_type():str() == config.dog_id and not mon:is_hallucination() and avatar:sees(mon:get_pos_ms()) then
      dogs[#dogs + 1] = { mon = mon, distance = policy.distance(here, mon:get_pos_ms()) }
    end
  end
  table.sort(dogs, function(a, b) return a.distance < b.distance end)
  if #dogs == 0 then
    gapi.add_msg(MsgType.info, "DoGS: no Labrador mutt in sight.")
    return nil
  end
  if #dogs == 1 then return dogs[1].mon end
  local list = UiList.new()
  list:title("DoGS - choose a dog")
  for i, row in ipairs(dogs) do
    local mon = row.mon
    list:add(i, string.format("#%s %s | HP %d/%d | %d tiles | %s%s", log.id(mon), mon:name(1), mon:get_hp(),
      mon:get_hp_max(), row.distance, on(mon, "dogs_trained") and "DoGS ON" or "DoGS OFF",
      mon.friendly == 0 and " | untamed" or ""))
  end
  local row = dogs[list:query()]
  return row and row.mon
end

---@param dog Monster
---@param choice integer
---@return string|nil message
function M.apply(dog, choice)
  if choice == 1 then
    if dog.friendly == 0 then return "DoGS: tame the dog first." end
    toggle(dog, "dogs_trained")
    if not on(dog, "dogs_trained") then attacks.disable(dog) end
  elseif choice == 2 then
    local index = 1
    for i, mode in ipairs(MODES) do
      if mode == dog:get_value("dogs_attack_mode") then index = i end
    end
    dog:set_value("dogs_attack_mode", MODES[index % #MODES + 1])
  elseif choice == 3 then dog:set_value("dogs_messages", messages_on(dog) and "0" or "1")
  elseif choice == 4 then dog:set_hp(dog:get_hp_max())
  elseif choice == 5 then roles.toggle(dog)
  else return nil end
  log.write("menu", "dog=" .. log.id(dog) .. " choice=" .. choice .. " trained=" .. tostring(on(dog, "dogs_trained")) ..
    " mode=" .. dog:get_value("dogs_attack_mode") .. " role=" .. role(dog) .. " hp=" .. dog:get_hp())
  return string.format("DoGS #%s: training %s, role %s, mode %s, HP %d/%d.", log.id(dog),
    on(dog, "dogs_trained") and "ON" or "OFF", role(dog),
    dog:get_value("dogs_attack_mode") == "" and "auto" or dog:get_value("dogs_attack_mode"), dog:get_hp(), dog:get_hp_max())
end

---@return integer
function M.open()
  local dog = pick_dog()
  if dog == nil then return 0 end
  local mode = dog:get_value("dogs_attack_mode") == "" and "auto" or dog:get_value("dogs_attack_mode")
  local menu = UiList.new()
  menu:title(string.format("DoGS #%s | %s | HP %d/%d | state %s | Takedown CD %d | Ankle Tear CD %d", log.id(dog),
    role(dog), dog:get_hp(), dog:get_hp_max(), dog:get_value("dogs_state") == "" and "-" or dog:get_value("dogs_state"),
    attacks.remaining(dog, "dogs_takedown"), attacks.remaining(dog, "dogs_ankle_tear")))
  menu:add(1, "Training: " .. (on(dog, "dogs_trained") and "ON" or "OFF") .. " (toggle)")
  menu:add(2, "Attack mode: " .. mode .. " (cycle auto / takedown / ankle)")
  menu:add(3, "State messages: " .. (messages_on(dog) and "ON" or "OFF") .. " (toggle)")
  menu:add(4, "Refill HP")
  menu:add(5, "Role: " .. role(dog) .. " (toggle guard / free)")
  local message = M.apply(dog, menu:query())
  if message then gapi.add_msg(MsgType.info, message) end
  return 0
end

return M
