-- Runs after data finalization, including --check-mods. Checks IDs only; no world access.
local config = require("dogs.config")

assert(MonsterTypeId.new(config.dog_id):is_valid(), "missing monster " .. config.dog_id)
for _, id in ipairs(config.blockers) do
  assert(EffectTypeId.new(id):is_valid(), "unknown blocker effect " .. id)
end
for _, id in ipairs({ "downed", "bleed", "dogs_ankle_wound", "docile" }) do
  assert(EffectTypeId.new(id):is_valid(), "unknown attack effect " .. id)
end
-- Monster bindings from BN 5442dd4 (#10504); older builds lack them.
for _, name in ipairs({ "attack_target", "movement_impaired", "is_dead_or_dying" }) do
  assert(Monster[name] ~= nil, "BN lacks Monster:" .. name .. " (needs 5442dd4 or later)")
end
gdebug.log_info("[DoGS] event=finalize result=pass")
