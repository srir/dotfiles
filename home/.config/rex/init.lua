-- Rex config ported from herdr (~/.config/herdr/config.toml) and the
-- Ghostty key routing in ~/.config/native-shortcuts-herd/ghostty.conf.
--
-- herdr workspace -> Rex session (sidebar)
-- herdr tab       -> Rex tab (unused here, like in herdr)
-- herdr pane      -> Rex pane
--
-- Check: rex config check     Apply: rex config reload (or "Reload Config" in the palette)

local P = "ctrl+b>" -- herdr prefix

-- Sessions (herdr workspaces) ------------------------------------------------

local HOME = os.getenv("HOME")

-- Rex doesn't remember which session a window showed before, so the switching
-- keys below note the session they leave, most recent first. Switching by
-- clicking in the sidebar isn't recorded.
local HISTORY_DIR = HOME .. "/.local/state/rex"
local HISTORY = HISTORY_DIR .. "/session-history"
rex.exec{ "mkdir", "-p", HISTORY_DIR }

local function session_history()
  local ids = {}
  local f = io.open(HISTORY)
  if f then
    for id in f:lines() do
      ids[#ids + 1] = id
    end
    f:close()
  end
  return ids
end

local function remember_session(id)
  if not id then return end
  local ids = { id }
  for _, other in ipairs(session_history()) do
    if other ~= id and #ids < 50 then
      ids[#ids + 1] = other
    end
  end
  local f = io.open(HISTORY, "w")
  if f then
    f:write(table.concat(ids, "\n"), "\n")
    f:close()
  end
end

-- Like rex.bind(key, action), but records the session being left first.
local switch_actions = {}
local function bind_switch(key, action)
  local name = "remember_then_" .. action:gsub("%.", "_")
  if not switch_actions[name] then
    switch_actions[name] = true
    rex.action{
      name = name,
      title = "Remember Session, Then " .. action,
      run = function(ctx)
        remember_session(ctx.session_id)
        rex.client.queue(action, {})
      end,
    }
  end
  rex.bind(key, name)
end

bind_switch(P .. "n", "session.new")
rex.bind(P .. "shift+n", "session.rename")
rex.bind(P .. "shift+d", "session.close")
bind_switch(P .. "w", "session.switch") -- herdr workspace picker
bind_switch(P .. "g", "session.switch") -- herdr goto
bind_switch("cmd+k", "session.switch")
bind_switch("ctrl+p", "session.switch")

bind_switch("ctrl+tab", "session.next")
bind_switch("ctrl+shift+tab", "session.previous")
bind_switch("ctrl+`", "session.previous") -- Ghostty workaround, kept for muscle memory

-- Go to the Nth session, like herdr's [keys.indexed] workspaces.
-- Sessions are numbered in the server's list order, which may differ from the
-- sidebar if you've dragged sessions around.
rex.action{
  name = "goto_session",
  title = "Go to Session by Number",
  args = { index = "integer" },
  run = function(ctx, args)
    local s = rex.call("session.list").sessions[args.index]
    if s then
      remember_session(ctx.session_id)
      rex.client.queue("session.select", { session_id = s.session_id })
    end
  end,
}

for i = 1, 9 do
  rex.bind("ctrl+shift+" .. i, "goto_session", { index = i })
  rex.bind("cmd+" .. i, "goto_session", { index = i })
end

-- Open the current session in a new window, and send this window back to the
-- session it showed before. "New Window" can't take a session, so
-- new_window.lua waits for the window, points it at this session, and destroys
-- the empty session the window started with.
local REX_BIN = HOME .. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
rex.action{
  name = "new_window_with_session",
  title = "New Window with This Session",
  run = function(ctx)
    local ids, live = {}, {}
    for _, s in ipairs(rex.call("session.list").sessions or {}) do
      ids[#ids + 1] = s.session_id
      live[s.session_id] = true
    end
    local previous
    for _, id in ipairs(session_history()) do
      if id ~= ctx.session_id and live[id] then
        previous = id
        break
      end
    end
    rex.exec{
      "sh", "-c", '"$0" do "$1" rex="$0" target="$2" existing="$3" >>"$4" 2>&1 &',
      REX_BIN, HOME .. "/.config/rex/new_window.lua", ctx.session_id, table.concat(ids, ","),
      HOME .. "/Library/Logs/rex-new-window.log",
    }
    -- Switch this window first: once the new window opens, it has focus.
    if previous then
      remember_session(ctx.session_id)
      rex.client.queue("session.select", { session_id = previous })
    end
    rex.client.queue("client.window.new", {})
  end,
}
rex.bind("cmd+shift+n", "new_window_with_session")

-- Tabs: unused, as in herdr. Take back the usual tab shortcuts so they can't
-- open or switch tabs by accident.
rex.unbind("cmd+t")
rex.unbind("cmd+shift+]")
rex.unbind("cmd+shift+[")

-- Panes ----------------------------------------------------------------------

rex.bind(P .. "h", "pane.focus.left")
rex.bind(P .. "j", "pane.focus.down")
rex.bind(P .. "k", "pane.focus.up")
rex.bind(P .. "l", "pane.focus.right")

rex.bind(P .. "shift+h", "pane.move.left")
rex.bind(P .. "shift+j", "pane.move.down")
rex.bind(P .. "shift+k", "pane.move.up")
rex.bind(P .. "shift+l", "pane.move.right")

rex.bind(P .. "tab", "pane.focus_next")
rex.bind(P .. "shift+tab", "pane.focus_previous")

rex.bind(P .. "v", "pane.split.right") -- herdr split_vertical (side by side)
rex.bind(P .. "-", "pane.split.down") -- herdr split_horizontal (stacked)
rex.bind(P .. "x", "pane.close")
rex.bind(P .. "z", "pane.zoom")

-- Resize mode, like herdr's prefix+r
rex.mode("resize", { exclusive = true })
rex.bind(P .. "r", "client.mode.enter", { name = "resize" })
for key, dir in pairs{ h = "left", j = "down", k = "up", l = "right",
                       left = "left", down = "down", up = "up", right = "right" } do
  rex.bind("resize/" .. key, "pane.resize", { direction = dir })
end
rex.bind("resize/escape", "client.mode.exit")
rex.bind("resize/enter", "client.mode.exit")

-- App --------------------------------------------------------------------------

rex.bind(P .. "b", "client.sidebar.toggle")
rex.bind(P .. "s", "client.settings")
rex.bind(P .. "shift+/", "client.palette.toggle") -- herdr help (prefix+?)
rex.bind(P .. "shift+r", "client.config.reload")
-- Import Ghostty's Duskfox theme (press once; re-press after editing the file)
rex.bind(P .. "shift+t", "client.theme.import", { path = HOME .. "/.config/ghostty/themes/Duskfox" })

-- Press the prefix twice to send a literal ctrl+b to the program
rex.bind(P .. "ctrl+b", "pane.send_key", { key = "ctrl+b" })

-- From Ghostty: shift+enter types a newline (multi-line prompts in agents)
rex.bind("shift+enter", "com.superlogical.terminal.write", { data = "\n" })
