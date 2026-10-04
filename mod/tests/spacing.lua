local attacks=require("lib.attacks")
local spacing=require("lib.spacing")
local M={}
function M.run()
  local function fixture(id,type_id,x,hp)
    local values={dogs_debug_id=id}
    local cooldown={dogs_takedown=3,dogs_ankle_tear=4}
    local mon={}
    function mon:get_value(key) return values[key] or "" end
    function mon:set_value(key,value) values[key]=value end
    function mon:get_type() return MonsterTypeId.new(type_id) end
    function mon:get_pos_ms() return TripointBubMs.new(x,10,0) end
    function mon:get_hp() return hp end
    function mon:set_hp(value) hp=value end
    function mon:has_effect(_id) return false end
    function mon:has_special_attack(key) return cooldown[key]~=nil end
    function mon:get_special_attack_cooldown(key) return cooldown[key] end
    function mon:set_special_attack_cooldown(key,value) cooldown[key]=value end
    return mon
  end
  local dog=fixture("spacing_fixture","mon_dog",10,3000)
  local enemy=fixture("enemy_fixture","mon_zombie",12,80)
  assert(attacks.ready(dog,enemy)==nil)
  dog:set_special_attack_cooldown("dogs_ankle_tear",0)
  assert(attacks.ready(dog,enemy)=="dogs_ankle_tear")
  dog:set_value("dogs_attack_mode","takedown")
  assert(attacks.ready(dog,enemy)==nil)
  assert(spacing.reach(dog,enemy)==1)
  assert(spacing.safe(dog,{enemy}))
  spacing.learn(dog,enemy,2,"fixture_confirmed")
  assert(not spacing.safe(dog,{enemy}))
  spacing.learn(dog,enemy,1,"fixture_shorter")
  assert(spacing.reach(dog,enemy)==2)
  local other=fixture("other_fixture","mon_zombie_tough",13,80)
  assert(spacing.reach(dog,other)==1)
  spacing.observe(dog,{other})
  dog:set_hp(2990)
  spacing.observe(dog,{other})
  assert(spacing.reach(dog,other)==3)
  local crowd=fixture("crowd_fixture","mon_zombie_resort_staff",14,80)
  spacing.observe(dog,{other,crowd})
  dog:set_hp(2980)
  spacing.observe(dog,{other,crowd})
  assert(spacing.reach(dog,crowd)==1)
  assert(attacks.message("dogs_takedown",2):find("Takedown",1,true))
  assert(attacks.message("dogs_ankle_tear",0):find("missed or stopped",1,true))
  gdebug.log_info("[DoGS] event=selftest spacing_assertions=12 result=pass fixture=mock")
end
return M
