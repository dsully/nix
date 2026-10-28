-- ctrl+, stands in for nvim's "," leader: a bare comma would stop commas from being typed.
local L = "ctrl+,>"

local DIRS = { h = "left", j = "down", k = "up", l = "right" }

-- Pickers run in a split below the pane, not a floating layer: Rex draws a layer's
-- unpainted cells see-through, so fzf would sit on top of the pane's text.
local function split_below(ctx, command)
    local _, err = rex.session.new_split({
        anchor_block_id = ctx.block_id,
        direction = "vertical",
        side = "after",
        ratio = 0.6,
        focus = true,
        layout = rex.layout.block({
            flavor = "com.superlogical.terminal.shell",
            options = { command = command },
        }),
    })
    if err ~= nil then
        error(err, 0)
    end
end

rex.action({
    name = "hints",
    title = "Copy or Type a Hint from the Pane",
    run = function(ctx)
        split_below(ctx, { "@rexHints@", ctx.block_id })
    end,
})

rex.action({
    name = "projects",
    title = "Open or Switch to a Project Session",
    run = function(ctx)
        split_below(ctx, { "@rexProjectPicker@" })
    end,
})

-- Find, as <leader>f
rex.bind(L .. "f>f", "projects")
rex.bind(L .. "f>w", "hints")
rex.bind(L .. "f>s", "session.switch")
rex.bind(L .. "f>i", "pane.insert_path")
rex.bind(L .. "f>k", "client.palette.toggle")

-- Panes, as <c-w>
for key, dir in pairs(DIRS) do
    rex.bind(L .. "w>" .. key, "pane.focus." .. dir)
    rex.bind(L .. "w>shift+" .. key, "pane.move." .. dir)
end
rex.bind(L .. "w>v", "pane.split.right")
rex.bind(L .. "w>s", "pane.split.down")
rex.bind(L .. "w>w", "pane.focus_next")
rex.bind(L .. "w>q", "pane.close")
rex.bind(L .. "w>o", "pane.zoom")
rex.bind(L .. "w>=", "pane.balance")
rex.bind(L .. "w>shift+t", "pane.move_to_new_tab")
rex.bind(L .. "w>r", "client.mode.enter", { name = "resize" })

rex.mode("resize", { exclusive = true })
for key, dir in pairs(DIRS) do
    rex.bind("resize/" .. key, "pane.resize", { direction = dir })
    rex.bind("resize/shift+" .. key, "pane.resize", { direction = dir, amount = 15 })
end
rex.bind("resize/=", "pane.balance")
rex.bind("resize/q", "client.mode.exit")
rex.bind("resize/enter", "client.mode.exit")

-- Tabs, as <leader>b buffers
rex.bind(L .. "b>n", "client.tab.new")
rex.bind(L .. "b>d", "client.tab.close")
rex.bind(L .. "b>r", "client.tab.rename")
rex.bind(L .. "b>l", "client.tab.next")
rex.bind(L .. "b>h", "client.tab.previous")
for i = 1, 9 do
    rex.bind(L .. "b>" .. i, "client.tab.goto", { index = i })
end

-- Sessions
rex.bind(L .. "s>s", "session.switch")
rex.bind(L .. "s>n", "session.new")
rex.bind(L .. "s>d", "session.close")
rex.bind(L .. "s>r", "session.rename")
rex.bind(L .. "s>l", "session.next")
rex.bind(L .. "s>h", "session.previous")

rex.bind(L .. "r", "client.config.reload")
