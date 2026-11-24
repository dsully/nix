--- Every nvim in a Rex pane writes <state>/<pid>.json so NvimOpen.app can
--- send clicked files to it. Written atomically, and only once the RPC
--- server exists, so a reader never sees a registration it cannot reach.
local M = {}

-- Substituted by nvim-open.nix with the directory NvimOpen reads.
local STATE = "@state@"

local function reg_path()
    return vim.fs.joinpath(STATE, vim.uv.os_getpid() .. ".json")
end

--- Write or refresh the registration; `time` marks the most recently used
--- nvim, which wins when several share a root.
function M.write()
    local sec, usec = vim.uv.gettimeofday()
    local cwd = vim.fn.getcwd(-1, -1)

    local data = vim.json.encode({
        root = vim.uv.fs_realpath(cwd) or cwd,
        session = vim.env.REX_SESSION or "",
        block = vim.env.REX_BLOCK,
        server = vim.v.servername,
        time = (sec or 0) + (usec or 0) / 1e6,
    })

    vim.fn.mkdir(STATE, "p")

    local path = reg_path()
    local tmp = path .. ".tmp"
    local fh, err = io.open(tmp, "w")
    local ok = fh ~= nil

    if fh then
        ok, err = fh:write(data .. "\n")
        fh:close()
    end

    if ok then
        ok, err = vim.uv.fs_rename(tmp, path)
    end

    if not ok then
        vim.notify("rex-nvim: cannot register: " .. tostring(err), vim.log.levels.WARN)
    end
end

function M.remove()
    vim.uv.fs_unlink(reg_path())
end

return M
