-- rex-nvim: register this nvim so files clicked in Rex open here.
-- Only nvim running inside a Rex pane ($REX_BLOCK set) registers.
if vim.g.loaded_rex_nvim then
    return
end

vim.g.loaded_rex_nvim = true

if (vim.env.REX_BLOCK or "") == "" then
    return
end

local registry = require("rex-nvim.registry")
local group = vim.api.nvim_create_augroup("rex-nvim", { clear = true })
local write = function()
    registry.write()
end

vim.api.nvim_create_autocmd("DirChanged", { group = group, pattern = "global", callback = write })
vim.api.nvim_create_autocmd("FocusGained", { group = group, callback = write })
vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
        registry.remove()
    end,
})

vim.api.nvim_create_autocmd("VimEnter", { group = group, once = true, callback = write })
