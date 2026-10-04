local M = {}
function M.register()
  local ai=require("lib.ai")
  local diagnostics=require("lib.diagnostics")
  game.monster_ai_functions["dogs_normal"] = ai.turn
  game.iuse_functions["DOGS_DEBUG_REMOTE"] = diagnostics.remote
  game.mod_runtime[game.current_mod].snapshot = diagnostics.snapshot
  require("tests.policy").run()
  require("lib.log").write("load","api=2 mode=MVP dog=mon_dog")
end
return M
