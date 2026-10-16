-- BN clears package.path after loading, so every module is resolved here and kept as a local.
-- Modules live under dogs/ to keep their package.loaded keys unique; "lib." is reserved for data/lua/lib.
local ai = require("dogs.ai")
local menu = require("dogs.menu")
local events = require("dogs.events")
local attacks = require("dogs.attacks")
local log = require("dogs.log")
local config = require("dogs.config")
local debug_mode = require("dogs.debug")

log.configure(game.mod_storage[game.current_mod])
debug_mode.configure(game.mod_storage[game.current_mod])

game.monster_ai_functions["dogs_normal"] = ai.turn
game.add_hook("on_creature_melee_attacked", events.on_melee)
game.add_hook("on_mon_death", events.on_death)
game.add_hook("on_creature_dodged", attacks.on_dodged)
game.iuse_functions["DOGS_COMMAND_WHISTLE"] = menu.whistle
gapi.register_action_menu_entry({ id = "dogs_debug", name = "DoGS debug", category = "debug", hotkey = "D", fn = menu.debug })
gapi.add_on_every_x_hook(TimeDuration.from_turns(config.summary_interval), events.summary)

require("dogs.tests").run()
gdebug.log_info("[DoGS] event=load build=claude-rebuild")
