local attacks=require("lib.attacks")
local laboratory=require("lib.laboratory")
local policy=require("lib.policy")
local M={}
function M.run()
  local values={}
  local cooldown={dogs_takedown=1,dogs_ankle_tear=2}
  local hp=11
  local max_hp=3000
  local dog={}
  function dog:get_value(key) return values[key] or "" end
  function dog:set_value(key,value) values[key]=value end
  function dog:get_special_attack_cooldown(id) return cooldown[id] end
  function dog:set_special_attack_cooldown(id,value) cooldown[id]=value end
  function dog:get_hp() return hp end
  function dog:get_hp_max() return max_hp end
  function dog:set_hp(value) hp=value end
  attacks.tick(dog,100)
  assert(cooldown.dogs_takedown==1)
  attacks.tick(dog,101)
  assert(cooldown.dogs_takedown==0 and cooldown.dogs_ankle_tear==1)
  attacks.tick(dog,101)
  assert(cooldown.dogs_ankle_tear==1)
  attacks.tick(dog,109)
  assert(cooldown.dogs_ankle_tear==0)
  cooldown.dogs_ankle_tear=8
  attacks.tick(dog,110)
  assert(cooldown.dogs_ankle_tear==7)
  laboratory.prepare(dog)
  assert(hp==3000)
  hp=20
  laboratory.prepare(dog)
  assert(hp==20)
  values.dogs_lab_hp_version=nil;max_hp=30
  laboratory.prepare(dog)
  assert(hp==20)
  assert(policy.accept_step(false,0,24,2,1,0,0,1,1,true))
  assert(not policy.accept_step(false,0,48,2,1,0,0,2,2,true))
  assert(not policy.accept_step(false,0,24,2,1,0,0,1,1,false))
  assert(not policy.accept_step(true,0,0,1,1,5,5,0,0,false))
  gdebug.log_info("[DoGS] event=selftest combat_assertions=12 result=pass fixture=mock")
end
return M
