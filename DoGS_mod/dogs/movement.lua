local policy = require("dogs.policy")
local log = require("dogs.log")

local M = {}

---@param origin TripointBubMs
---@return TripointBubMs[]
local function free_neighbors(origin)
  local map = gapi.get_map()
  local out = {}
  for dx = -1, 1 do
    for dy = -1, 1 do
      if dx ~= 0 or dy ~= 0 then
        local pos = TripointBubMs.new(origin.x + dx, origin.y + dy, origin.z)
        if not map:is_out_of_bounds(pos) and gapi.get_creature_at(pos, true) == nil then
          out[#out + 1] = pos
        end
      end
    end
  end
  return out
end

---One engine-costed step chosen by policy.rank_steps.
---Returns true when the action was spent (moved, or a failed move still cost moves).
---@param dog Monster
---@param kind string "retreat" | "flee" | "disengage" | "regroup"
---@param enemies TripointBubMs[]
---@param quiet boolean|nil caller logs the no-step case itself
---@return boolean
function M.step(dog, kind, enemies, quiet)
  local origin = dog:get_pos_ms()
  local player = gapi.get_avatar():get_pos_ms()
  local ranked = policy.rank_steps(kind, origin, free_neighbors(origin), enemies, player)
  for _, pos in ipairs(ranked) do
    local moves = dog:get_moves()
    if dog:move_to(pos, false, false, 1.0) then
      log.write("step", "dog=" .. log.id(dog) .. " kind=" .. kind .. " from=" .. origin.x .. "," .. origin.y ..
        " to=" .. pos.x .. "," .. pos.y .. " risk=" .. policy.risk(origin, enemies) .. "->" .. policy.risk(pos, enemies))
      return true
    end
    if dog:get_moves() ~= moves then return true end
  end
  if not quiet then
    log.write("step_failed", "dog=" .. log.id(dog) .. " kind=" .. kind .. " acceptable=" .. #ranked)
  end
  return false
end

return M
