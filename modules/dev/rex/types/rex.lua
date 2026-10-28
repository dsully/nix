---@meta rex

-- https://www.superlogical.com/rex/docs/reference/lua

---@class rex.Ctx
---@field session_id? string
---@field block_id? string
---@field client_id? string
---@field origin? string
---@field server? string

---@class rex.KeyEvent
---@field keybinding string
---@field prefix? string[]

---@alias rex.KeyFn fun(ctx: rex.Ctx, ev: rex.KeyEvent): boolean?

---@class rex.Binding
---@field key string
---@field mode? string
---@field action? string
---@field fn? rex.KeyFn
---@field args? table
---@field source string

---@class rex.BindingFilter
---@field key? string
---@field mode? string
---@field action? string

---@class rex.Mode
---@field name string
---@field exclusive boolean
---@field source string

---@class rex.ModeOptions
---@field exclusive? boolean

---@class rex.ActionSpec
---@field name string
---@field title string
---@field run fun(ctx: rex.Ctx, args: table): any
---@field description? string
---@field category? string
---@field keywords? string
---@field args? table<string, string>|table
---@field repeats? boolean

---@class rex.ExecOpts
---@field cwd? string
---@field env? table<string, string|false>
---@field clear_env? boolean
---@field stdin? string
---@field timeout? number
---@field stdout? false
---@field stderr? false
---@field text? false

---@class rex.ExecStartOpts
---@field cwd? string
---@field env? table<string, string|false>
---@field clear_env? boolean
---@field stdin? string|true
---@field timeout? number
---@field stdout? false|fun(data: string)
---@field stderr? false|fun(data: string)
---@field text? false
---@field detach? boolean

---@class rex.ExecResult
---@field code integer
---@field signal? string
---@field stdout string
---@field stderr string
---@field timed_out boolean
---@field ok boolean

---@class rex.Process
---@field pid integer
local Process = {}

---@param seconds? number
---@return rex.ExecResult?
---@return string? err
function Process:wait(seconds) end

---@param data string
---@return true?
---@return string? err
function Process:write(data) end

function Process:close_stdin() end

---@param signal? string|integer
function Process:kill(signal) end

---@return boolean
function Process:running() end

---@class rex.Timer
local Timer = {}

function Timer:cancel() end

---@return boolean
function Timer:active() end

---@class rex.Layout

---@class rex.TerminalOptions
---@field command? string[]
---@field shell? string
---@field cwd? string
---@field initial_input? string
---@field exit? { on_completion: boolean }

---@class rex.LayoutBlockSpec
---@field flavor string
---@field label? string
---@field options? rex.TerminalOptions|table

---@class rex.layout
local layout = {}

---@param spec rex.LayoutBlockSpec
---@return rex.Layout
function layout.block(spec) end

---@param ratio number
---@param a rex.Layout
---@param b rex.Layout
---@return rex.Layout
function layout.horizontal(ratio, a, b) end

---@param ratio number
---@param a rex.Layout
---@param b rex.Layout
---@return rex.Layout
function layout.vertical(ratio, a, b) end

---@alias rex.Method fun(args?: table): table?, string?

---@class rex.NewSplitArgs
---@field session_id? string
---@field anchor_id? string
---@field window_id? string
---@field direction "horizontal"|"vertical"
---@field side "before"|"after"
---@field layout rex.Layout
---@field ratio? number
---@field focus? boolean

---@class rex.NewSplitResult
---@field anchor_id? string
---@field block_ids? string[]
---@field split_ids? string[]
---@field revision integer

-- `rex api describe session.<method>` has each method's arguments and result.
---@class rex.session
---@field view rex.Method
---@field list_blocks rex.Method
---@field list_clients rex.Method
---@field describe_block rex.Method
---@field new_window rex.Method
---@field new_split fun(args: rex.NewSplitArgs): rex.NewSplitResult?, string?
---@field new_block rex.Method
---@field new_layer rex.Method
---@field close_window rex.Method
---@field close_layer rex.Method
---@field move_block rex.Method
---@field swap_blocks rex.Method
---@field detach_block rex.Method
---@field float_block rex.Method
---@field zoom_block rex.Method
---@field resize_pane rex.Method
---@field resize_layer rex.Method
---@field raise_layer rex.Method
---@field lower_layer rex.Method
---@field move_window rex.Method
---@field focus_block rex.Method
---@field focus_window rex.Method
---@field focus_direction rex.Method
---@field focus_next_pane rex.Method
---@field focus_previous_pane rex.Method
---@field focus_next_window rex.Method
---@field focus_previous_window rex.Method
---@field set_label rex.Method
---@field set_window_label rex.Method
---@field set_block_label rex.Method
---@field attach rex.Method
---@field detach rex.Method
---@field help rex.Method
---@field [string] rex.Method

---@class rex.block
---@field call fun(creator: string, method: string, args?: table): table?, string?

---@class rex.client
---@field queue fun(name: string, args?: table)

---@class rex.json
---@field encode fun(value: any, opts?: { indent?: boolean }): string?, string?
---@field decode fun(text: string): any, string?

---@class rex.exec
---@overload fun(argv: string[], opts?: rex.ExecOpts): rex.ExecResult?, string?
---@field start fun(argv: string[], opts?: rex.ExecStartOpts): rex.Process?, string?

---@class rex.Server
---@field session rex.session
---@field block rex.block
---@field call fun(method: string, args?: table): table?, string?

---@class rex.HostSpec
---@field label string
---@field endpoints? string[]
---@field endpoint? string
---@field id? string
---@field icon? string

---@class rex
---@field session rex.session
---@field block rex.block
---@field client rex.client
---@field layout rex.layout
---@field json rex.json
---@field exec rex.exec
---@field args? table Script only.
---@field session_id? string Script only.
---@field block_id? string Script only.
rex = {}

---@param key string
---@param action string
---@param args? table
---@overload fun(key: string, fn: rex.KeyFn)
function rex.bind(key, action, args) end

---@param key string
---@param target? string|rex.KeyFn
---@return integer removed
---@overload fun(spec: { mode: string }): integer
---@overload fun(binding: rex.Binding): integer
function rex.unbind(key, target) end

---@param name string
---@param options? rex.ModeOptions
function rex.mode(name, options) end

---@param filter? rex.BindingFilter
---@return rex.Binding[]
function rex.bindings(filter) end

---@return rex.Mode[]
function rex.modes() end

---@param spec rex.ActionSpec
function rex.action(spec) end

---@param name string
---@param args? table
---@return any result
---@return string? err
function rex.invoke(name, args) end

---@param method string
---@param args? table
---@return table?
---@return string? err
function rex.call(method, args) end

---Script only.
---@param event string
---@param fn fun(ctx: rex.Ctx, ev: table)
function rex.on(event, fn) end

---Script only.
---@param event string
---@param filter? table|fun(ev: table, ctx: rex.Ctx): boolean
---@param timeout? number
---@return table? ev
---@return rex.Ctx|string ctx_or_timeout
function rex.wait(event, filter, timeout) end

---Script only.
---@param seconds number
function rex.sleep(seconds) end

---Script only.
---@param code? integer
function rex.stop(code) end

---@param spec rex.HostSpec
function rex.host(spec) end

---@return string[]
function rex.servers() end

---@param label string
---@return rex.Server
function rex.server(label) end

---Script only.
---@param seconds number
---@param fn fun(ctx: rex.Ctx)
---@return rex.Timer
function rex.after(seconds, fn) end

---Script only.
---@param seconds number
---@param fn fun(ctx: rex.Ctx)
---@return rex.Timer
function rex.every(seconds, fn) end

---@param level "debug"|"info"|"warn"|"error"
---@param message string
---@overload fun(message: string)
function rex.log(level, message) end
