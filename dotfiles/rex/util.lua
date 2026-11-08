local M = {}

M.TERMINAL = "com.superlogical.terminal"

function M.find_block(window, block_id)
    for i, layer in ipairs(window.layers or {}) do
        local hit

        local function walk(node)
            if not node or hit then
                return
            end

            if node.block_id == block_id then
                hit = node
            elseif node.split then
                walk(node.split.before)
                walk(node.split.after)
            end
        end

        walk(layer.layout)

        if hit ~= nil then
            return hit, layer, i
        end
    end
end

function M.active_window(view)
    for i, w in ipairs(view.windows or {}) do
        if w.window_id == view.active_window_id then
            return w, i
        end
    end
end

function M.cwd_of(block_id)
    local ok, r = pcall(rex.block.call, M.TERMINAL, "pwd", { block_id = block_id })
    local url = ok and r and (r.pwd or r.url)

    return type(url) == "string" and url:gsub("^file://[^/]*", "") or nil
end

return M
