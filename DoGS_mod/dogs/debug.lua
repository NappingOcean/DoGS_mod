-- Debug mode: logs, state messages and the experiment tools. Off by default; saved with the world.
local M = {}

local storage = {}

---@param data table mod_storage table, persisted with the world
function M.configure(data)
  storage = data
end

---@return boolean
function M.on() return storage.debug == true end

---@param value boolean
function M.set(value) storage.debug = value end

return M
