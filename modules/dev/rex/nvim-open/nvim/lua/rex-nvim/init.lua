--- Opens files sent by NvimOpen.app over RPC (--remote-expr + luaeval).
--- Not --remote: its :drop runs in the current window, so it fails in a
--- 'winfixbuf' sidebar, replaces a sidebar's buffer otherwise, and stops on
--- the swap-file prompt while the caller waits.
local M = {}

--- A window a file may be opened in: a normal, non-floating window whose
--- buffer is a regular file buffer and that is not pinned with 'winfixbuf'.
--- @param win integer
--- @return boolean
local function usable(win)
    if vim.api.nvim_win_get_config(win).relative ~= "" then
        return false
    end

    if vim.wo[win].winfixbuf then
        return false
    end

    return vim.bo[vim.api.nvim_win_get_buf(win)].buftype == ""
end

--- Pick the window for path in the current tab: one already showing it, else
--- the current window if usable, else the first usable one, else a new split.
--- @param path string
--- @return integer win
--- @return boolean showing whether win already shows path
local function target_window(path)
    local wins = vim.api.nvim_tabpage_list_wins(0)

    for _, win in ipairs(wins) do
        local name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))

        if name ~= "" and vim.uv.fs_realpath(name) == path then
            return win, true
        end
    end

    local current = vim.api.nvim_get_current_win()

    if usable(current) then
        return current, false
    end

    for _, win in ipairs(wins) do
        if usable(win) then
            return win, false
        end
    end

    vim.cmd.vsplit({ mods = { split = "botright" } })

    return vim.api.nvim_get_current_win(), false
end

--- Open path in this nvim and put the cursor on line/col when given.
--- An existing swap file does not prompt (shortmess+=A): the caller cannot
--- answer a prompt, and the file opens as it would after choosing "Edit anyway".
--- @param path string absolute physical path
--- @param line integer|nil 1-based line, 0 or nil for none
--- @param col integer|nil 1-based column, 0 or nil for none
--- @return string "ok", or the error message
function M.open(path, line, col)
    local ok, err = pcall(function()
        if vim.api.nvim_get_mode().mode:sub(1, 1) ~= "n" then
            vim.cmd.stopinsert()
        end

        local win, showing = target_window(path)
        vim.api.nvim_set_current_win(win)

        if not showing then
            local shortmess = vim.o.shortmess
            vim.o.shortmess = shortmess .. "A"

            local edit_ok, edit_err = pcall(vim.cmd.edit, vim.fn.fnameescape(path))

            vim.o.shortmess = shortmess

            if not edit_ok then
                error(edit_err, 0)
            end
        end

        if line and line > 0 then
            local last = vim.api.nvim_buf_line_count(0)
            local target_col = (col and col > 0) and col - 1 or 0

            vim.api.nvim_win_set_cursor(0, { math.min(line, last), target_col })
            vim.cmd("normal! zz")
        end
    end)

    if ok then
        return "ok"
    end

    return tostring(err)
end

return M
