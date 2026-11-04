-- Runs inside `rex do -e`: one server round-trip for every session's panes.
local function call(method, args)
  local ok, res = pcall(rex.call, method, args)
  if ok then return res end
end

local sessions = {}
for i, s in ipairs(call("session.list").sessions or {}) do
  -- Reading a session's view and its blocks needs this connection attached to it.
  call("session.attach", { session_id = s.session_id })
  local view = call("session.view", { session_id = s.session_id }) or {}
  local panes = {}
  for _, w in ipairs(view.windows or {}) do
    for _, layer in ipairs(w.layers or {}) do
      for _, b in ipairs(layer.blocks or {}) do
        local p = {
          block_id = b.block_id,
          label = b.label,
          window_id = w.window_id,
          focused = view.active_window_id == w.window_id and w.focused_block_id == b.block_id,
        }
        if b.creator_name == "com.superlogical.terminal" then
          local args = { session_id = s.session_id, block_id = b.block_id }
          local status = call("com.superlogical.terminal.program_status", args)
          local latest
          for _, r in ipairs((status and status.records) or {}) do
            if not latest or (r.updated_at or "") > (latest.updated_at or "") then latest = r end
          end
          if latest then
            p.app = latest.effective_app or latest.app
            p.state = latest.state
            p.msg = latest.msg
          end
          local title = call("com.superlogical.terminal.title", args)
          p.title = title and title.title
          local proc = call("com.superlogical.terminal.process", args)
          if proc and proc.foreground then
            p.process = proc.foreground.argv0 or proc.foreground.name
            p.cwd = proc.foreground.cwd
          end
        end
        panes[#panes + 1] = p
      end
    end
  end
  sessions[#sessions + 1] = { index = i, session_id = s.session_id, label = s.label, panes = panes }
end
return { sessions = sessions }
