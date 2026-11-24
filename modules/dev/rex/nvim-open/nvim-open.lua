-- rex do nvim-open.lua --args '{"nvim":NVIM,"session":SESSION?,"focus":[[SESSION, BLOCK], ...],"files":[[PATH, LINE, COL], ...]}'
-- NvimOpen has already sent what it could to registered nvims; FOCUS lists the panes that took a file.
-- Each remaining PATH (absolute, physical) opens in a new nvim tab in SESSION, the caller's, when given;
-- else in the session whose terminal cwd is its deepest ancestor ($HOME and above never match);
-- else in the "files" session.

local TERMINAL = "com.superlogical.terminal"
local HOME = os.getenv("HOME")
local ARGS = assert(rex.args)

local function call(method, args)
    return assert(rex.call(method, args))
end

-- Session methods fail with "not attached" on sessions other than the one rex do targets.
call("session.attach_all", { event_scope = "session" })

local function say(msg)
    io.stderr:write("rex-nvim: " .. msg .. "\n")
end

local function under(dir, path)
    return path:sub(1, #dir + 1) == dir .. "/"
end

local function name(path)
    return path:match("[^/]+$")
end

local function url_path(url)
    local path = url:gsub("^file://[^/]*", ""):gsub("%%(%x%x)", function(h)
        return string.char(tonumber(h, 16) --[[@as integer]])
    end)

    return path
end

local function project_session(file, exclude)
    local best, best_dir = nil, "" ---@type string?, string

    for _, s in ipairs(call("session.list").sessions) do
        if s.session_id ~= exclude then
            for _, b in ipairs((rex.call("session.list_blocks", { session_id = s.session_id }) or {}).blocks or {}) do
                if b.flavor:find(TERMINAL, 1, true) == 1 then
                    local ok, r = pcall(rex.block.call, TERMINAL, "pwd", { session_id = s.session_id, block_id = b.block_id })
                    local dir = ok and r and r.pwd and url_path(r.pwd)

                    if dir and #dir > #best_dir and under(dir, file) and dir ~= HOME and not under(dir, HOME) then
                        best, best_dir = s.session_id, dir
                    end
                end
            end
        end
    end

    return best, best_dir
end

local function open_tab(sid, dir, f)
    local cmd = { ARGS.nvim, ("+call cursor(%d, %d)"):format(math.max(f[2], 1), math.max(f[3], 1)), "--", f[1] }

    local layout =
        rex.layout.block({ flavor = TERMINAL .. ".shell", label = name(f[1]), options = { command = cmd, cwd = dir } })

    if sid then
        call("session.new_window", { session_id = sid, layout = layout, window_label = name(f[1]) })
        return sid
    end

    return call(
        "session.create",
        { label = "files", initial_windows = { { layout = layout, window_label = name(f[1]) } } }
    ).session_id
end

---@return string session_id
local function route(f)
    if ARGS.session then
        return open_tab(ARGS.session, f[1]:match("^(.*)/"), f)
    end

    local files_sid

    for _, s in ipairs(call("session.list").sessions) do
        if s.label == "files" then
            files_sid = s.session_id
        end
    end

    local sid, dir = project_session(f[1], files_sid)

    if sid then
        return open_tab(sid, dir, f)
    end

    return open_tab(files_sid, f[1]:match("^(.*)/"), f)
end

local function app_connected()
    for _, c in ipairs(call("client.list").clients) do
        if c.info.kind == "app" and c.connection_state == "connected" then
            return true
        end
    end
end

local shown, failed ---@type string?, boolean?

for _, p in ipairs(ARGS.focus or {}) do
    pcall(rex.call, "session.focus_block", { session_id = p[1], block_id = p[2] })
    shown = p[1]
end

for _, f in ipairs(ARGS.files or {}) do
    local ok, sid = pcall(route, f)
    if ok then
        shown = sid
    else
        failed = true
        say("could not open " .. name(f[1]) .. ": " .. tostring(sid))
    end
end

-- NvimOpen may have just launched Rex.app; only the app can switch sessions.
for _ = 1, shown and 50 or 0 do
    if app_connected() then
        rex.client.queue("session.select", { session_id = shown })
        break
    end

    rex.sleep(0.1)
end

if failed then
    rex.stop(1)
end
