-- Player commands (the command whistle) and the debug menu (action menu > Debug > DoGS debug).
local config = require("dogs.config")
local policy = require("dogs.policy")
local attacks = require("dogs.attacks")
local log = require("dogs.log")
local roles = require("dogs.role")
local breed = require("dogs.breed")
local debug_mode = require("dogs.debug")

local M = {}

local MODES = { "auto", "takedown", "ankle" }
local ROLE_TEXT = {
  guard = "Guard: stay close and take on enemies coming at you",
  free = "Free: fight like an ordinary pet, with control attacks",
  harass = "Harass: hold up the next enemy (experimental)",
}

---Tamed DoGS dogs the player can see, nearest first; the player picks one if there are several.
---@param title string
---@return Monster|nil
local function pick_dog(title)
  local avatar = gapi.get_avatar()
  local here = avatar:get_pos_ms()
  local dogs = {}
  for _, mon in ipairs(gapi.get_all_monsters()) do
    if breed.is_dog(mon) and mon.friendly ~= 0 and avatar:sees(mon:get_pos_ms()) then
      dogs[#dogs + 1] = { mon = mon, distance = policy.distance(here, mon:get_pos_ms()) }
    end
  end
  table.sort(dogs, function(a, b) return a.distance < b.distance end)
  if #dogs == 0 then
    gapi.add_msg(MsgType.info, "No tamed dog in sight.")
    return nil
  end
  if #dogs == 1 then return dogs[1].mon end
  local list = UiList.new()
  list:title(title)
  for i, row in ipairs(dogs) do
    local mon = row.mon
    list:add(i, string.format("%s%s | HP %d/%d | %d tiles | %s | training %d", mon:name(1),
      debug_mode.on() and (" #" .. log.id(mon)) or "", mon:get_hp(), mon:get_hp_max(), row.distance,
      roles.get(mon), breed.level(mon)))
  end
  local row = dogs[list:query()]
  return row and row.mon
end

---Command whistle (game.iuse_functions): tell one dog which role to take.
---@return integer charges used
function M.whistle()
  local dog = pick_dog("Whistle to which dog?")
  if dog == nil then return 0 end
  if not breed.can(dog, "judgment") then
    gapi.add_msg(MsgType.info, string.format("Your %s does not know the whistle signals yet (needs training level %d).",
      dog:name(1), config.training.judgment))
    return 0
  end
  local choices = { "guard", "free" }
  if roles.harass_allowed(dog) then choices[#choices + 1] = "harass" end
  local list = UiList.new()
  list:title(string.format("Signal your %s (now: %s)", dog:name(1), roles.get(dog)))
  for i, value in ipairs(choices) do list:add(i, ROLE_TEXT[value]) end
  local value = choices[list:query()]
  if value == nil then return 0 end
  roles.set(dog, value)
  log.write("menu", "dog=" .. log.id(dog) .. " source=whistle role=" .. value)
  gapi.add_msg(MsgType.info, string.format("You whistle. Your %s takes the %s role.", dog:name(1), value))
  return 0
end

---@param dog Monster
---@param choice integer
---@return string|nil message
function M.apply(dog, choice)
  if choice == 1 then dog:set_hp(dog:get_hp_max())
  elseif choice == 2 then
    local index = 1
    for i, mode in ipairs(MODES) do
      if mode == dog:get_value("dogs_attack_mode") then index = i end
    end
    dog:set_value("dogs_attack_mode", MODES[index % #MODES + 1])
  elseif choice == 3 then
    -- none -> 0 .. 5 -> none
    local level = tonumber(dog:get_value("dogs_debug_level"))
    dog:set_value("dogs_debug_level", level == nil and "0" or (level < 5 and tostring(level + 1) or ""))
  elseif choice == 4 then
    local next_role = { guard = "free", free = "harass", harass = "guard" }
    roles.set(dog, next_role[dog:get_value("dogs_role")] or "free")
  elseif choice == 5 then
    dog:set_value("dogs_recall_until", tostring(gapi.current_turn():to_turn() + config.harass.recall))
  else return nil end
  log.write("menu", "dog=" .. log.id(dog) .. " choice=" .. choice .. " level=" .. breed.level(dog) ..
    " mode=" .. dog:get_value("dogs_attack_mode") .. " role=" .. roles.get(dog) .. " hp=" .. dog:get_hp())
  return string.format("DoGS #%s: training %d, role %s, mode %s, HP %d/%d.", log.id(dog), breed.level(dog),
    roles.get(dog), dog:get_value("dogs_attack_mode") == "" and "auto" or dog:get_value("dogs_attack_mode"),
    dog:get_hp(), dog:get_hp_max())
end

---Experiment tools for one dog. Only reachable in debug mode.
local function dog_tools()
  local dog = pick_dog("DoGS debug - choose a dog")
  if dog == nil then return end
  local mode = dog:get_value("dogs_attack_mode") == "" and "auto" or dog:get_value("dogs_attack_mode")
  local override = dog:get_value("dogs_debug_level")
  local menu = UiList.new()
  menu:title(string.format("DoGS #%s %s | %s | HP %d/%d | state %s | Takedown CD %d | Ankle Tear CD %d", log.id(dog),
    dog:get_type():str(), roles.get(dog), dog:get_hp(), dog:get_hp_max(),
    dog:get_value("dogs_state") == "" and "-" or dog:get_value("dogs_state"),
    attacks.remaining(dog, "dogs_takedown"), attacks.remaining(dog, "dogs_ankle_tear")))
  menu:add(1, "Refill HP")
  menu:add(2, "Attack mode: " .. mode .. " (cycle auto / takedown / ankle)")
  menu:add(3, string.format("Training level override: %s (BN level %d; cycle none / 0-5)",
    override == "" and "none" or override, dog.training_level))
  menu:add(4, "Role: " .. roles.get(dog) .. " (cycle guard / free / harass)")
  menu:add(5, "Call back (stop harassing for a while)")
  local message = M.apply(dog, menu:query())
  if message then gapi.add_msg(MsgType.info, message) end
end

---Action menu > Debug > DoGS debug.
---@return integer
function M.debug()
  local menu = UiList.new()
  menu:title("DoGS debug")
  menu:add(1, "Debug mode: " .. (debug_mode.on() and "ON" or "OFF") .. " (toggle: log, state messages, tools)")
  if debug_mode.on() then menu:add(2, "Dog tools...") end
  local choice = menu:query()
  if choice == 1 then
    debug_mode.set(not debug_mode.on())
    gdebug.log_info("[DoGS] event=debug on=" .. tostring(debug_mode.on()))
    gapi.add_msg(MsgType.info, "DoGS debug mode " .. (debug_mode.on() and "ON." or "OFF."))
  elseif choice == 2 and debug_mode.on() then
    dog_tools()
  end
  return 0
end

return M
