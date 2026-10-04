-- Runs after data finalization, including --check-mods. Checks IDs only; no world access.
local config = require("dogs.config")

assert(MonsterTypeId.new(config.dog_id):is_valid(), "missing monster " .. config.dog_id)
for _, id in ipairs(config.blockers) do
  assert(EffectTypeId.new(id):is_valid(), "unknown blocker effect " .. id)
end
for _, id in ipairs({ "downed", "bleed", "dogs_ankle_wound" }) do
  assert(EffectTypeId.new(id):is_valid(), "unknown attack effect " .. id)
end
gdebug.log_info("[DoGS] event=finalize result=pass")
