local M = {}

local storage = {}

---@param data table mod_storage table, persisted with the world
function M.configure(data)
  storage = data
end

---Stable per-entity number for log correlation; saved with the creature.
---@param mon Monster
---@return string
function M.id(mon)
  local id = mon:get_value("dogs_id")
  if id == "" then
    storage.next_id = (storage.next_id or 0) + 1
    id = tostring(storage.next_id)
    mon:set_value("dogs_id", id)
  end
  return id
end

---@param event string
---@param fields string
function M.write(event, fields)
  gdebug.log_info("[DoGS] event=" .. event .. " turn=" .. gapi.current_turn():to_turn() .. " " .. fields)
end

return M
