local util = require("util")

local SCRATCH = { cols = 120, rows = 30, max_w = 0.6, max_h = 0.5 }
local scratch = {} -- window_id -> block_id

-- Layer bounds are window fractions, so derive the window's size in cells
-- from the focused pane's size and its share of the window.
local function scratch_bounds(window, block_id)
    local w, h = SCRATCH.max_w, SCRATCH.max_h
    local ok, size = pcall(rex.block.call, util.TERMINAL, "size", { block_id = block_id })
    local node = util.find_block(window, block_id)
    local rect = node and node.rect

    if ok and size and size.columns and size.rows then
        w = math.min(SCRATCH.cols * (rect and rect[3] or 1) / size.columns, SCRATCH.max_w)
        h = math.min(SCRATCH.rows * (rect and rect[4] or 1) / size.rows, SCRATCH.max_h)
    end

    return { (1 - w) / 2, (1 - h) / 2, w, h }
end

rex.action({
    name = "scratch_toggle",
    title = "Toggle Scratch Terminal",
    run = function(ctx)
        local view, err = rex.session.view({})

        if err then
            error(err, 0)
        end

        local win = util.active_window(view)

        if not win then
            return
        end

        local id = scratch[win.window_id]

        if id ~= nil then
            local _, layer, idx = util.find_block(win, id)

            if layer and idx > 1 then
                local _, derr = rex.session.detach_block({ block_id = id })
                if derr then
                    rex.session.close_layer({ layer_id = layer.layer_id })
                    scratch[win.window_id] = nil
                end
                return
            end

            local _, ferr = rex.session.float_block({
                block_id = id,
                bounds = scratch_bounds(win, win.focused_block_id or ctx.block_id),
            })

            if not ferr then
                rex.session.focus_block({ block_id = id })
                return
            end

            scratch[win.window_id] = nil
        end

        local r, nerr = rex.session.new_layer({
            window_id = win.window_id,
            bounds = scratch_bounds(win, ctx.block_id),
            focus = true,

            layout = rex.layout.block({
                flavor = "com.superlogical.terminal.shell",
                label = "scratch",
                options = { cwd = util.cwd_of(ctx.block_id) },
            }),
        })

        if nerr then
            error(nerr, 0)
        end

        if r ~= nil then
            scratch[win.window_id] = r.block_ids[1]
        end
    end,
})

rex.bind("ctrl+\\", "scratch_toggle")
