local config=require("lib.config")
local policy=require("lib.policy")
local log=require("lib.log")
local M={}
local storage
local last={}
local hp={}
---@param data table
function M.configure(data) storage=data; last={}; hp={} end
---@param mon Monster
---@return string
function M.id(mon)
  local id=mon:get_value("dogs_debug_id")
  if id == "" then
    storage.telemetry_counter=(storage.telemetry_counter or 0)+1
    id=tostring(storage.telemetry_counter)
    mon:set_value("dogs_debug_id",id)
  end
  return id
end
---@param mon Monster
---@param reason string
---@param force boolean|nil
function M.observe(mon,reason,force)
  local id=M.id(mon)
  local p=mon:get_pos_ms()
  local text="entity="..id.." type="..mon:get_type():str().." pos="..p.x..","..p.y..","..p.z..
    " hp="..mon:get_hp().." max_hp="..mon:get_hp_max().." speed="..mon:get_speed()..
    " friendly="..mon.friendly.." trained="..mon:get_value("dogs_trained").." action="..mon:get_value("dogs_action")..
    " mode="..mon:get_value("dogs_attack_mode")
  for _,effect in ipairs({"downed","bleed","dogs_ankle_wound"}) do
    text=text.." "..effect.."="..tostring(mon:has_effect(EffectTypeId.new(effect)))
  end
  for _,attack in ipairs(config.attacks) do
    if mon:has_special_attack(attack) then
      text=text.." "..attack.."_cooldown="..tostring(mon:get_special_attack_cooldown(attack))..
        " "..attack.."_enabled="..tostring(mon:special_attack_enabled(attack))
    end
  end
  if force or last[id] ~= text then
    log.write("state",text.." moves="..mon:get_moves().." reason="..reason.." turn="..gapi.current_turn():to_turn().." hp_delta="..tostring(hp[id] and mon:get_hp()-hp[id] or 0))
    last[id]=text
    hp[id]=mon:get_hp()
  end
end
---@param dog Monster
function M.targets(dog)
  for _,mon in ipairs(gapi.get_all_monsters()) do
    if mon ~= dog and not mon:is_hallucination() and
      policy.distance(dog:get_pos_ms(),mon:get_pos_ms()) <= config.radius and dog:sees(mon:get_pos_ms()) then
      M.observe(mon,"near_dog")
    end
  end
end
function M.poll()
  for _,mon in ipairs(gapi.get_all_monsters()) do
    if mon:get_type():str() == config.dog_id and not mon:is_hallucination() then
      M.observe(mon,"heartbeat",true)
      M.targets(mon)
    end
  end
end
return M
