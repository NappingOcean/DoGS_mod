-- Runs after data finalization, including --check-mods. No world mutation.
require("tests.guards").run()
assert(EffectTypeId.new("dogs_ankle_wound"):is_valid())
assert(MonsterTypeId.new("mon_dog"):is_valid())
require("lib.log").write("finalize","definitions=valid")
require("tests.telemetry").run(game.mod_storage[game.current_mod])
