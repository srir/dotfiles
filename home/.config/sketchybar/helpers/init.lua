-- Add the sketchybar module to the package cpath
package.cpath = package.cpath .. ";/Users/" .. os.getenv("USER") .. "/.local/share/sketchybar_lua/?.so"

-- Only build helpers if binaries don't exist (avoid blocking reload)
local config_dir = os.getenv("CONFIG_DIR") or os.getenv("HOME") .. "/.config/sketchybar"
local cpu_bin = config_dir .. "/helpers/event_providers/cpu_load/bin/cpu_load"
local net_bin = config_dir .. "/helpers/event_providers/network_load/bin/network_load"

local function file_exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

if not file_exists(cpu_bin) or not file_exists(net_bin) then
    os.execute("(cd " .. config_dir .. "/helpers && make)")
end
