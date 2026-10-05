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
  return dog:is_hallucination()
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
    " kept=false player_before=" .. dog:get_value("dogs_probe_player") ..
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

  -- Docile is the stock dog whistle's "follow closely and stop attacking". Respect it: keep only
  -- the safety veto above and leave the rest to the engine, which picks no target while docile.
  local is_docile = dog:has_effect(docile)
  if is_docile ~= (dog:get_value("dogs_docile") == "1") then
    dog:set_value("dogs_docile", is_docile and "1" or "")
    log.write("docile", "dog=" .. log.id(dog) .. " on=" .. tostring(is_docile))
  end
  if is_docile then
    dog:set_value("dogs_disengage", "")
    return false
  end

  -- 2. After a control attack: bite while a neighbor is down, break off once it stands.
  if dog:get_value("dogs_disengage") == "1" then
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

  -- 4. Role. Guard replaces the leash with its own tighter one.
  if role.get(dog) == "guard" then return guard(dog, obs, positions, now) end

  -- 5. Leash (Free role).
  if state == "REGROUP" then return regroup(dog, positions, now) end

  -- 6. Nothing to add.
  return false
end

return M
