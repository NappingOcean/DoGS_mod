local M = {}
function M.run()
  local ai=require("lib.ai")
  local config=require("lib.config")
  local disabled={}
  local flags={}
  local values={}
  local dog={friendly=-1}
  function dog:set_special_attack_enabled(id,enabled) disabled[id]=enabled end
  function dog:get_type() return MonsterTypeId.new(config.dog_id) end
  function dog:get_value(key) return values[key] or "" end
  function dog:set_value(key,value) values[key]=value end
  function dog:has_effect(id) return flags[id:str()] == true end
  function dog:is_hallucination() return false end
  -- Any perception/movement access would fail: guards must return before it.
  assert(ai.turn(dog)==false)
  for _,id in ipairs(config.attacks) do assert(disabled[id]==false) end
  assert(disabled.EAT_FOOD==nil)
  values.dogs_trained="1"
  dog.friendly=0
  assert(ai.turn(dog)==false)
  dog.friendly=-1
  flags.tied=true
  assert(ai.turn(dog)==false)
  assert(values.dogs_action=="BLOCKED")
  flags.tied=nil
  flags.downed=true
  assert(ai.turn(dog)==false)
  gdebug.log_info("[DoGS] event=selftest guard_assertions=8 result=pass fixture=mock")
end
return M
