local M={}
---@param real_storage table
function M.run(real_storage)
  local t=require("lib.telemetry")
  local fixture_storage={}
  t.configure(fixture_storage)
  local function fixture()
    local values={}
    local mon={friendly=-1}
    function mon:get_value(key) return values[key] or "" end
    function mon:set_value(key,value) values[key]=value end
    function mon:get_type() return MonsterTypeId.new("mon_dog") end
    function mon:get_pos_ms() return TripointBubMs.new(10,10,0) end
    function mon:get_hp() return 30 end
    function mon:get_hp_max() return 30 end
    function mon:get_speed() return 150 end
    function mon:get_moves() return 0 end
    function mon:has_effect(_id) return false end
    function mon:has_special_attack(_id) return false end
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
  t.configure(real_storage)
  gdebug.log_info("[DoGS] event=selftest telemetry_assertions=4 result=pass fixture=mock")
end
return M
