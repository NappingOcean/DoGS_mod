-- Judgment layer over the stock pet AI (docs/en/design.md, section 2).
-- Returning false hands the action to the engine: targeting, pathing, following, normal bites.
local config = require("dogs.config")
local policy = require("dogs.policy")
local perception = require("dogs.perception")
local movement = require("dogs.movement")
local attacks = require("dogs.attacks")
local role = require("dogs.role")
local log = require("dogs.log")

local M = {}

local downed = EffectTypeId.new("downed")
local docile = EffectTypeId.new("docile")

local blockers = {}
for i, id in ipairs(config.blockers) do blockers[i] = EffectTypeId.new(id) end

---@param dog Monster
---@return boolean
local function restrained(dog)
  for _, id in ipairs(blockers) do
    if dog:has_effect(id) then return true end
  end
  -- movement_impaired also covers heavysnare/lightsnare, which have no JSON ID to list.
  return dog:movement_impaired() or dog:is_hallucination()
end

---@param dog Monster
---@param now integer
---@param obs DogsObservation
---@return string
local function update_state(dog, now, obs)
  local previous = dog:get_value("dogs_state")
  local entered = tonumber(dog:get_value("dogs_state_turn")) or now
  local state = policy.next_state(previous, now - entered, obs)
  if state ~= previous then
    dog:set_value("dogs_state", state)
    dog:set_value("dogs_state_turn", tostring(now))
    dog:set_value("dogs_holding", "")
    log.write("decide", "dog=" .. log.id(dog) .. " from=" .. (previous == "" and "none" or previous) .. " to=" .. state ..
      string.format(" hp=%.2f adjacent=%d nearby=%d nearest=%s player=%s", obs.hp, obs.adjacent, obs.nearby,
        tostring(obs.nearest), tostring(obs.player)))
    -- Messages default to on; the menu stores "0" to silence them.
    if dog:get_value("dogs_messages") ~= "0" then
      local reason = state == "RETREAT" and policy.low_hp(obs) and " (wounded, falling back behind you)" or ""
      gapi.add_msg(MsgType.info, "DoGS #" .. log.id(dog) .. ": " .. state .. reason)
    end
  end
  return state
end

-- Delegated regroup: E3 showed the engine keeps a destination set before returning false
-- only while it has no target. Only a replaced destination is logged, as an exception.
-- Stored across turns, so absolute coordinates: bubble coordinates shift with the map.
---@param pos TripointBubMs
---@return string
local function abs_text(pos)
  local a = gapi.bub_to_abs(pos)
  return a.x .. "," .. a.y .. "," .. a.z
end

---@param dog Monster
---@param now integer
local function report_probe(dog, now)
  local pending = dog:get_value("dogs_probe_dest")
  if pending == "" then return end
  dog:set_value("dogs_probe_dest", "")
  local now_dest = abs_text(dog:move_target())
  if now_dest == pending then return end
  -- The engine has a target DoGS did not count; stop delegating for a while.
  dog:set_value("dogs_delegate_block", tostring(now + config.regroup.block))
  log.write("probe_result", "dog=" .. log.id(dog) .. " set=" .. pending .. " now=" .. now_dest ..
    " kept=false engine_target=" .. tostring(dog:attack_target() ~= nil) .. " player_before=" .. dog:get_value("dogs_probe_player") ..
    " player_after=" .. policy.distance(dog:get_pos_ms(), gapi.get_avatar():get_pos_ms()))
end

---@param dog Monster
---@return boolean
local function delegate_regroup(dog)
  local player = gapi.get_avatar():get_pos_ms()
  dog:set_move_target(player)
  dog:set_value("dogs_probe_dest", abs_text(player))
  dog:set_value("dogs_probe_player", tostring(policy.distance(dog:get_pos_ms(), player)))
  return false
end

---Back toward the player. The engine keeps a destination only while it has no target (E3), so
---delegate only when no hostile is visible at any range and the engine has not overridden one
---recently (E5). Otherwise DoGS steps.
---@param dog Monster
---@param positions TripointBubMs[]
---@param now integer
---@return boolean handled
local function regroup(dog, positions, now)
  local blocked = (tonumber(dog:get_value("dogs_delegate_block")) or 0) > now
  if not blocked and #perception.enemies(dog, math.huge) == 0 then return delegate_regroup(dog) end
  return movement.step(dog, "regroup", positions)
end

---Guard role: stay within reach of the player and take on only enemies that threaten the player
---or close on the dog. Other enemies are ignored, so the engine never chases them.
---@param dog Monster
---@param obs DogsObservation
---@param positions TripointBubMs[]
---@param now integer
---@return boolean handled
local function guard(dog, obs, positions, now)
  if obs.player > config.guard.radius then return regroup(dog, positions, now) end
  if obs.adjacent > 0 then return false end -- the stock AI bites what is in front of the dog
  local target = policy.guard_target(dog:get_pos_ms(), positions, gapi.get_avatar():get_pos_ms())
  if target and movement.step(dog, "intercept", positions, false, target) then return true end
  return true -- by the player: wait
end

---Whom a monster's last plan targets: "player", "dog", "other", or "none" (wandering, or the
---target is out of its sight). Lua AI runs before plan, so this is the previous action's choice.
---@param mon Monster
---@param dog Monster
---@return string
local function chasing(mon, dog)
  local target = mon:attack_target()
  if target == nil then return "none" end
  if target:is_avatar() then return "player" end
  local a, b = target:get_pos_ms(), dog:get_pos_ms()
  if a.x == b.x and a.y == b.y and a.z == b.z then return "dog" end
  return "other"
end

---Harass log, once per game turn: whom the held-up enemy is heading for. `toward` compares its
---destination with the dog and the player; `chases` is its attack target.
---@param dog Monster
---@param target Monster
---@param now integer
---@param positions TripointBubMs[]
local function track(dog, target, now, positions)
  if dog:get_value("dogs_track_turn") == tostring(now) then return end
  dog:set_value("dogs_track_turn", tostring(now))
  local here, player, pos = dog:get_pos_ms(), gapi.get_avatar():get_pos_ms(), target:get_pos_ms()
  local dest = target:move_target()
  local to_dog, to_player = policy.distance(dest, here), policy.distance(dest, player)
  local toward = to_dog < to_player and "dog" or (to_player < to_dog and "player" or "tie")
  log.write("track", "dog=" .. log.id(dog) .. " target=" .. log.id(target) .. " dog_dist=" .. policy.distance(pos, here) ..
    " player_dist=" .. policy.distance(pos, player) .. " toward=" .. toward ..
    " chases=" .. chasing(target, dog) .. " on_player=" .. policy.adjacent(player, positions))
end

---Harass role v0 (docs/en/harass.md): while the player is engaged, hold up the next enemy to
---arrive: control it when an attack is ready, otherwise keep hold_min..hold_max tiles from it so it
---chases the dog. Ends automatically after `finish` turns with no enemy on the player, or on recall.
---@param dog Monster
---@param obs DogsObservation
---@param enemies Monster[]
---@param positions TripointBubMs[]
---@param now integer
---@return boolean handled
local function harass(dog, obs, enemies, positions, now)
  local h = config.harass
  local player = gapi.get_avatar():get_pos_ms()
  if obs.player > h.range then return regroup(dog, positions, now) end
  if policy.adjacent(player, positions) > 0 then dog:set_value("dogs_engaged_turn", tostring(now)) end
  local engaged = tonumber(dog:get_value("dogs_engaged_turn"))
  local recalled = (tonumber(dog:get_value("dogs_recall_until")) or 0) > now
  local current = nil
  for i, enemy in ipairs(enemies) do
    if enemy:get_value("dogs_id") ~= "" and enemy:get_value("dogs_id") == dog:get_value("dogs_harass_target") then current = i end
  end
  local index = (not recalled and engaged and now - engaged < h.finish) and policy.harass_target(positions, player, current) or nil
  if index == nil then
    if dog:get_value("dogs_harass_target") ~= "" then
      dog:set_value("dogs_harass_target", "")
      log.write("harass_end", "dog=" .. log.id(dog) .. " recalled=" .. tostring(recalled))
    end
    return guard(dog, obs, positions, now)
  end
  local target, goal = enemies[index], positions[index]
  if dog:get_value("dogs_harass_target") ~= log.id(target) then
    dog:set_value("dogs_harass_target", log.id(target))
    log.write("harass_target", "dog=" .. log.id(dog) .. " target=" .. log.id(target) ..
      " player_dist=" .. policy.distance(goal, player))
  end
  track(dog, target, now, positions)
  local ready = attacks.choose(dog, target, now) ~= nil
  if ready and obs.adjacent == 0 and movement.step(dog, "intercept", positions, false, goal, h.range) then return true end
  if movement.step(dog, "kite", positions, true, goal, h.range) then return true end
  if obs.adjacent > 0 then return false end -- cornered in contact: defend
  return true -- holding position at the right distance
end

---@param dog Monster
---@return boolean handled
function M.turn(dog)
  -- Disable before every possible fallback so the stock scheduler cannot pick DoGS attacks.
  attacks.disable(dog)
  if dog:get_type():str() ~= config.dog_id or dog:get_value("dogs_trained") ~= "1" or dog.friendly == 0 then
    return false
  end
  if restrained(dog) then return false end

  local now = gapi.current_turn():to_turn()
  report_probe(dog, now)
  local enemies = perception.enemies(dog)
  local obs, positions = perception.observe(dog, enemies)
  -- Object permanence: remember when an enemy was last perceived.
  if #enemies > 0 then dog:set_value("dogs_threat_turn", tostring(now)) end
  local last_threat = tonumber(dog:get_value("dogs_threat_turn"))
  obs.since_threat = last_threat and (now - last_threat) or math.huge
  local state = update_state(dog, now, obs)

  -- 1. Safety veto.
  if state == "RETREAT" then
    if policy.low_hp(obs) then
      -- Out of the fight: fall back behind the player; the player deals with the pursuer.
      if movement.step(dog, "flee", positions, true) then
        dog:set_value("dogs_holding", "")
        return true
      end
      if obs.adjacent > 0 then return false end -- cornered: let the engine fight
      -- Behind the player, or no closer tile without contact: wait. Logged once per wait.
      if dog:get_value("dogs_holding") ~= "1" then
        dog:set_value("dogs_holding", "1")
        log.write("hold", "dog=" .. log.id(dog) .. " player=" .. tostring(obs.player) .. " nearest=" .. tostring(obs.nearest))
      end
      return true
    end
    if policy.risk(dog:get_pos_ms(), positions) == 0 then return true end -- already clear: hold
    if movement.step(dog, "retreat", positions) then return true end
    return false -- cornered: let the engine fight
  end

  -- Docile is the stock dog whistle's "follow closely and stop attacking". Keep only the safety veto
  -- above. The engine picks no new target while docile but keeps biting an adjacent enemy (E7), so
  -- a trained dog completes the order by stepping out of contact first.
  local is_docile = dog:has_effect(docile)
  if is_docile ~= (dog:get_value("dogs_docile") == "1") then
    dog:set_value("dogs_docile", is_docile and "1" or "")
    log.write("docile", "dog=" .. log.id(dog) .. " on=" .. tostring(is_docile))
  end
  if is_docile then
    dog:set_value("dogs_disengage", "")
    if obs.adjacent > 0 then
      local moved = movement.step(dog, "disengage", positions)
      log.write("docile_disengage", "dog=" .. log.id(dog) .. " moved=" .. tostring(moved))
      if moved then return true end
    end
    return false -- out of contact: the engine follows; cornered: it defends itself
  end

  -- 2. After a control attack: bite while a neighbor is down, break off once it stands.
  -- Harass does not fight in contact, so it skips the bite and goes straight to holding distance.
  if dog:get_value("dogs_disengage") == "1" and role.get(dog) == "harass" then
    dog:set_value("dogs_disengage", "")
  elseif dog:get_value("dogs_disengage") == "1" then
    if obs.adjacent == 0 then
      dog:set_value("dogs_disengage", "")
    elseif perception.adjacent_with(dog, enemies, downed) then
      return false -- the stock AI bites the downed enemy
    else
      dog:set_value("dogs_disengage", "")
      local moved = movement.step(dog, "disengage", positions)
      log.write("disengage", "dog=" .. log.id(dog) .. " moved=" .. tostring(moved))
      if moved then return true end
    end
  end

  -- 3. Control opportunity.
  if state == "DEFAULT" and policy.control_window(obs) then
    local target = perception.adjacent_enemy(dog, enemies)
    local id = target and attacks.choose(dog, target, now)
    if target and id and attacks.use(dog, target, id, now) then
      dog:set_value("dogs_disengage", "1")
      return true
    end
  end

  -- 4. Role. Guard and Harass replace the leash with their own.
  if role.get(dog) == "guard" then return guard(dog, obs, positions, now) end
  if role.get(dog) == "harass" then return harass(dog, obs, enemies, positions, now) end

  -- 5. Leash (Free role).
  if state == "REGROUP" then return regroup(dog, positions, now) end

  -- 6. Nothing to add.
  return false
end

return M
