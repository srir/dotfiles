-- Helper for the new_window_with_session action in init.lua, run as:
--   rex do new_window.lua rex=<rex binary> target=<session id> existing=<id,id,...>
--
-- Rex's "New Window" always starts a fresh session. Once that session appears,
-- show the target session in the new window instead, then destroy the fresh one.

local existing = {}
for id in string.gmatch(rex.args.existing or "", "[^,]+") do
  existing[id] = true
end

local function fresh_session()
  for _, s in ipairs(rex.call("session.list").sessions or {}) do
    if not existing[s.session_id] then
      return s.session_id
    end
  end
end

local fresh
for _ = 1, 30 do
  fresh = fresh_session()
  if fresh then break end
  rex.sleep(0.1)
end
if not fresh then return end

-- Wait for the new window to take focus, so the select lands in it.
rex.sleep(0.3)
rex.exec{ rex.args.rex, "do", "session.select", "session_id=" .. rex.args.target }
rex.sleep(0.3)
-- Destroying a session needs this connection attached to it.
rex.call("session.attach", { session_id = fresh })
local _, err = rex.call("session.destroy", { session_id = fresh })
if err then print(os.date("%Y-%m-%d %H:%M:%S"), "destroying", fresh, err) end
