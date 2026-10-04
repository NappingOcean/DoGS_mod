local diagnostics=require("lib.diagnostics")
local attacks=require("lib.attacks")
local M={}
---@param real_storage table
function M.run(real_storage)
  local t=require("lib.telemetry")
  local fixture_storage={}
  t.configure(fixture_storage)
  local function fixture()
    local values={}
    local hp=30
    local mon={friendly=-1}
    function mon:get_value(key) return values[key] or "" end
    function mon:set_value(key,value) values[key]=value end
    function mon:get_type() return MonsterTypeId.new("mon_dog") end
    function mon:get_pos_ms() return TripointBubMs.new(10,10,0) end
    function mon:get_hp() return hp end
    function mon:set_hp(value) hp=value end
    function mon:get_hp_max() return 30 end
    function mon:get_speed() return 150 end
    function mon:get_moves() return 0 end
    function mon:has_effect(_id) return false end
    function mon:has_special_attack(_id) return false end
    function mon:special_attack_ready(_id) return false end
    function mon:get_special_attack_cooldown(_id) return 1 end
    function mon:set_special_attack_enabled(_id,_enabled) end
    function mon:set_target(_target) end
    return mon
  end
  local a,b=fixture(),fixture()
  local id=t.id(a)
  assert(id==t.id(a))
  assert(id~=t.id(b))
  assert(a:get_value("dogs_debug_id")==id)
  t.observe(a,"fixture")
  t.configure(fixture_storage)
  assert(t.id(a)==id)
  t.observe(a,"fixture_reload")
  -- Simulate BN's post-load callback environment, restoring it on failure.
  local saved_path=package.path
  package.path=nil
  local ok,err=pcall(function()
    assert(diagnostics.apply(a,3) ~= nil)
    assert(attacks.try(a,b) == false)
    a:set_hp(5)
    assert(diagnostics.apply(a,8) ~= nil and a:get_hp()==a:get_hp_max())
  end)
  package.path=saved_path
  t.configure(real_storage)
  if not ok then error(err) end
  gdebug.log_info("[DoGS] event=selftest telemetry_assertions=7 result=pass fixture=mock")
end
return M
