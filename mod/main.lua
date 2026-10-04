local M = {}
function M.register()
  local ai=require("lib.ai")
  local diagnostics=require("lib.diagnostics")
  local telemetry=require("lib.telemetry")
  local spacing=require("lib.spacing")
  game.add_hook("on_creature_melee_attacked",spacing.on_melee)
  telemetry.configure(game.mod_storage[game.current_mod])
  game.monster_ai_functions["dogs_normal"] = function(dog)
    telemetry.observe(dog,"before_ai")
    local handled=ai.turn(dog)
    telemetry.observe(dog,"after_ai")
    return handled
  end
  gapi.register_action_menu_entry({id="dogs_laboratory",name="DoGS laboratory",category="misc",fn=diagnostics.open})
  gapi.add_on_every_x_hook(TimeDuration.from_turns(5),function() telemetry.poll() end)
  game.iuse_functions["DOGS_DEBUG_REMOTE"] = diagnostics.remote

  require("tests.policy").run()
  require("lib.log").write("load","api=2 mode=MVP dog=mon_dog")
end
return M
