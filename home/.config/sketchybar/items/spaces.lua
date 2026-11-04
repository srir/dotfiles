local colors = require("colors").sections.spaces
local icons = require("icons")
local icon_map = require("helpers.icon_map")

-- Track space items so we can update them on display change
local space_items = {}

-- Debounce state for refresh_display_assignments
local refresh_pending = false
local refresh_timer_id = 0

-- Cache focused workspace to avoid IPC round-trips (updated on aerospace_workspace_change)
local focused_workspace = nil

-- Resolve aerospace monitor-id -> sketchybar display id.
--
-- These two number displays differently: aerospace goes left-to-right,
-- top-to-bottom, while sketchybar uses the CoreGraphics arrangement-id. On a
-- laptop plus two externals they disagree, which lands each bar on the wrong
-- screen. NSScreen ordering does NOT bridge them either -- it matched
-- aerospace here, not sketchybar.
--
-- helpers/display_map.py re-sorts the frames from `sketchybar --query
-- displays` the way aerospace orders monitors and prints the correspondence,
-- so the mapping is measured from the live setup rather than assumed.
--
-- Calls back with a monitor-id -> display table, or nil when there is a
-- single monitor (signals "active", so items are drawn wherever the bar is).
local function with_display_mapping(callback)
    sbar.exec(os.getenv("HOME") .. "/.config/sketchybar/helpers/display_map.py", function(output)
        local displays = {}
        local count = 0

        for line in output:gmatch("[^\r\n]+") do
            local monitor_id, display_id = line:match("^%s*(%d+)%s+(%d+)%s*$")
            if monitor_id and display_id then
                displays[tonumber(monitor_id)] = tonumber(display_id)
                count = count + 1
            end
        end

        -- No usable mapping (helper failed, or a single screen): fall back to
        -- "active" so every item still draws instead of vanishing.
        callback(count > 1 and displays or nil)
    end)
end

-- Parse "workspace monitor-id" lines
local function parse_workspace_monitor(line)
    local ws, mon = line:match("^(%S+)%s+(%d+)$")
    return ws, tonumber(mon)
end

-- Add app icons and hide if empty + unfocused (for single workspace)
local function add_windows(space, space_name)
    sbar.exec("aerospace list-windows --format %{app-name} --workspace " .. space_name, function(windows)
        local icon_line = ""
        for app in windows:gmatch("[^\r\n]+") do
            local icon = icon_map[app] or icon_map["Default"]
            icon_line = icon_line .. " " .. icon
        end

        local label_text = icon_line == "" and "—" or icon_line
        local padding = icon_line == "" and 8 or 12

        -- Auto-hide if empty and not focused (use cached focused_workspace, no IPC needed)
        local is_focused = focused_workspace == space_name
        local should_draw = icon_line ~= "" or is_focused

        sbar.animate("tanh", 10, function()
            space:set({
                label = {
                    string = label_text,
                    padding_right = padding,
                },
                drawing = should_draw,
            })
        end)
    end)
end

-- Refresh all workspaces in a single call (avoids N separate shell invocations)
local function refresh_all_windows()
    sbar.exec("aerospace list-windows --all --format '%{app-name}|%{workspace}'", function(output)
        -- Build a map of workspace -> list of app names
        local workspace_apps = {}
        for line in output:gmatch("[^\r\n]+") do
            local app, ws = line:match("^(.+)|(%S+)$")
            if app and ws then
                workspace_apps[ws] = workspace_apps[ws] or {}
                table.insert(workspace_apps[ws], app)
            end
        end

        -- Update each space item
        for space_name, space in pairs(space_items) do
            local apps = workspace_apps[space_name] or {}
            local icon_line = ""
            for _, app in ipairs(apps) do
                local icon = icon_map[app] or icon_map["Default"]
                icon_line = icon_line .. " " .. icon
            end

            local label_text = icon_line == "" and "—" or icon_line
            local padding = icon_line == "" and 8 or 12
            local is_focused = focused_workspace == space_name
            local should_draw = icon_line ~= "" or is_focused

            space:set({
                label = {
                    string = label_text,
                    padding_right = padding,
                },
                drawing = should_draw,
            })
        end
    end)
end

-- Update all space items with current display assignments
local function refresh_display_assignments()
    with_display_mapping(function(displays)
        sbar.exec("aerospace list-workspaces --all --format '%{workspace} %{monitor-id}'",
            function(workspaces_output)
                for line in workspaces_output:gmatch("[^\r\n]+") do
                    local space_name, monitor_id = parse_workspace_monitor(line)
                    local space = space_items[space_name]

                    if space and space_name then
                        -- On single monitor (displays is nil), use "active" to clear display restriction
                        -- On multi-monitor, assign to specific display
                        local target_display = displays and displays[monitor_id] or "active"
                        -- Update display assignment, let add_windows determine visibility
                        space:set({ display = target_display })
                        add_windows(space, space_name)
                    end
                end
            end)
    end)
end

-- Create a watcher item for display changes and periodic refresh
local display_watcher = sbar.add("item", "display_watcher", {
    drawing = false,
    updates = "on",  -- Receive events even when not visible
    update_freq = 5, -- Periodic refresh every 5 seconds
})

-- Periodic refresh of all workspaces to catch any sync issues
-- (replaces high-frequency space_windows_change which caused deadlocks)
-- Uses single aerospace call to minimize IPC overhead
display_watcher:subscribe("routine", function()
    refresh_all_windows()
end)

-- Debounced refresh: cancels previous pending refresh and schedules a new one
local function schedule_refresh(delay_seconds)
    refresh_timer_id = refresh_timer_id + 1
    local my_timer_id = refresh_timer_id

    sbar.exec("sleep " .. delay_seconds .. " && echo done", function()
        -- Only run if this is still the latest scheduled refresh
        if my_timer_id == refresh_timer_id and not refresh_pending then
            refresh_pending = true
            refresh_display_assignments()
            -- Reset after a short delay to allow next refresh
            sbar.exec("sleep 1 && echo done", function()
                refresh_pending = false
            end)
        end
    end)
end

display_watcher:subscribe("display_change", function()
    -- Single debounced refresh after aerospace settles
    schedule_refresh(1.5)
end)

-- Also refresh on system_woke (lid open, dock/undock)
display_watcher:subscribe("system_woke", function()
    -- Slightly longer delay for system wake
    schedule_refresh(2)
end)

-- Initialize focused workspace cache, then initialize spaces
sbar.exec("aerospace list-workspaces --focused", function(focused_output)
    focused_workspace = focused_output:match("^%s*(.-)%s*$")
end)

-- Initialize spaces
with_display_mapping(function(displays)
    sbar.exec("aerospace list-workspaces --all --format '%{workspace} %{monitor-id}'",
        function(workspaces_output)
            for line in workspaces_output:gmatch("[^\r\n]+") do
                local space_name, monitor_id = parse_workspace_monitor(line)
                if not space_name then goto continue end

                local is_first = space_name == "1"
                -- On single monitor (displays is nil), use "active"; on multi-monitor, use specific display
                local target_display = displays and displays[monitor_id] or "active"

                    local space = sbar.add("item", "space." .. space_name, {
                        icon = {
                            string = space_name,
                            color = colors.icon.color,
                            highlight_color = colors.icon.highlight,
                            padding_left = 8,
                        },
                        label = {
                            font = "sketchybar-app-font:Regular:14.0",
                            string = "",
                            color = colors.label.color,
                            highlight_color = colors.label.highlight,
                            y_offset = -1,
                        },
                        click_script = "aerospace workspace " .. space_name,
                        padding_left = is_first and 0 or 4,
                        drawing = false, -- hide by default until checked
                        display = target_display,
                    })

                    -- Store for later updates
                    space_items[space_name] = space

                    add_windows(space, space_name)

                    space:subscribe("aerospace_workspace_change", function(env)
                        -- Update cached focused workspace (used by add_windows)
                        focused_workspace = env.FOCUSED_WORKSPACE

                        local selected = env.FOCUSED_WORKSPACE == space_name
                        space:set({
                            icon = { highlight = selected },
                            label = { highlight = selected },
                        })

                        if selected then
                            sbar.animate("tanh", 3, function()
                                space:set({
                                    background = { shadow = { distance = 0 } },
                                    y_offset = -4,
                                    padding_left = 8,
                                    padding_right = 0,
                                })
                                space:set({
                                    background = { shadow = { distance = 4 } },
                                    y_offset = 0,
                                    padding_left = 4,
                                    padding_right = 4,
                                })
                            end)
                        end

                        add_windows(space, space_name)

                        -- Always make focused space visible
                        space:set({ drawing = true })
                    end)

                    -- NOTE: space_windows_change disabled - fires too frequently and
                    -- causes IPC deadlock with sketchybar. Windows are still updated
                    -- on aerospace_workspace_change which is sufficient.
                    -- space:subscribe("space_windows_change", function()
                    --     add_windows(space, space_name)
                    -- end)

                    space:subscribe("mouse.clicked", function()
                        sbar.animate("tanh", 8, function()
                            space:set({
                                background = { shadow = { distance = 0 } },
                                y_offset = -4,
                                padding_left = 8,
                                padding_right = 0,
                            })
                            space:set({
                                background = { shadow = { distance = 4 } },
                                y_offset = 0,
                                padding_left = 4,
                                padding_right = 4,
                            })
                        end)
                    end)

                ::continue::
            end
        end)
    end)
