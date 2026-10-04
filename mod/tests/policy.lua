local M = {}
function M.run()
  local p=require("lib.policy")
  assert(p.choose(0.4,0,0,1,1,1)=="RECOVER")
  assert(p.choose(1,2,2,1,1,1)=="RETREAT")
  assert(p.choose(1,0,4,1,2,2)=="RETREAT")
  assert(p.choose(1,0,0,7,1,1)=="REGROUP")
  assert(p.choose(1,0,0,1,nil,nil)=="REGROUP")
  assert(p.choose(1,1,1,1,1,1)=="ASSIST")
  assert(p.choose(1,0,1,1,2,3)=="INTERCEPT")
  assert(p.choose(1,0,1,1,3,4)=="SKIRMISH")
  assert(p.distance(TripointBubMs.new(1,2,0),TripointBubMs.new(3,5,0))==3)
  assert(p.distance(TripointBubMs.new(1,2,0),TripointBubMs.new(1,2,1))==math.huge)
  gdebug.log_info("[DoGS] event=selftest policy_assertions=10 result=pass")
end
return M
