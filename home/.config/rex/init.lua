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

rex.bind(P .. "n", "session.new")
rex.bind(P .. "shift+n", "session.rename")
rex.bind(P .. "shift+d", "session.close")
rex.bind(P .. "w", "session.switch") -- herdr workspace picker
rex.bind(P .. "g", "session.switch") -- herdr goto
rex.bind("cmd+k", "session.switch")
rex.bind("ctrl+p", "session.switch")

rex.bind("ctrl+tab", "session.next")
rex.bind("ctrl+shift+tab", "session.previous")
rex.bind("ctrl+`", "session.previous") -- Ghostty workaround, kept for muscle memory

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
      rex.client.queue("session.select", { session_id = s.session_id })
    end
  end,
}

for i = 1, 9 do
  rex.bind("ctrl+shift+" .. i, "goto_session", { index = i })
  rex.bind("cmd+" .. i, "goto_session", { index = i })
end

-- Open the current session in a new window. "New Window" can't take a session,
-- so new_window.lua waits for the window, points it at this session, and
-- destroys the empty session the window started with.
local HOME = os.getenv("HOME")
local REX_BIN = HOME .. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
rex.action{
  name = "new_window_with_session",
  title = "New Window with This Session",
  run = function(ctx)
    local ids = {}
    for _, s in ipairs(rex.call("session.list").sessions or {}) do
      ids[#ids + 1] = s.session_id
    end
    rex.exec{
      "sh", "-c", '"$0" do "$1" rex="$0" target="$2" existing="$3" >>"$4" 2>&1 &',
      REX_BIN, HOME .. "/.config/rex/new_window.lua", ctx.session_id, table.concat(ids, ","),
      HOME .. "/Library/Logs/rex-new-window.log",
    }
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
rex.bind(P .. "shift+t", "client.theme.import", { path = os.getenv("HOME") .. "/.config/ghostty/themes/Duskfox" })

-- Press the prefix twice to send a literal ctrl+b to the program
rex.bind(P .. "ctrl+b", "pane.send_key", { key = "ctrl+b" })

-- From Ghostty: shift+enter types a newline (multi-line prompts in agents)
rex.bind("shift+enter", "com.superlogical.terminal.write", { data = "\n" })
