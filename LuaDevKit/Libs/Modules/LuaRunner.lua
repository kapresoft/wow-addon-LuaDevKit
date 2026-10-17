--- @type LDK_Core_Namespace
local ns = select(2, ...)
local PrettyPrint, TraceKit = ns.O.LibPrettyPrint, ns.O.LibTraceKit
local L = ns:GetLocale()

--- @alias LDK_OutputKind 'print'|'error'
--- @alias LDK_OutputFn fun(text: string, kind: LDK_OutputKind?)

--[[-----------------------------------------------------------------------------
LuaRunner
-------------------------------------------------------------------------------]]

--- @class LDK_LuaRunner
local o = {}; ns.O.LuaRunner = o

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]

local TRACE_COLOR = 'FFAB25'

-- The env's helpers: signature, then its locale key.
local HELPERS = {
  { 'p(...)', 'Editor Helpers::p' },
  { 't(...)', 'Editor Helpers::t' },
  { 'fm(value)', 'Editor Helpers::fm' },
  { 'fs(value)', 'Editor Helpers::fs' },
  { 'fv(value)', 'Editor Helpers::fv' },
  { 'inspect(val) or ti(val)', 'Editor Helpers::inspect' },
  { 'help()', 'Editor Helpers::help' },
}

-- Closing example of the helpers list; '--' lines show its output.
local HELPERS_EXAMPLE = {
  'local tbl = {',
  "   hello = 'world',",
  '   start = 1, stop = 10,',
  '   callback = function() end }',
  "p('tbl=', fm(tbl))",
  '-- tbl= {',
  '--   callback = <function: ...>,',
  "--   hello = 'world',",
  '--   start = 1,',
  '--   stop = 10',
  '-- }',
}

--- @type LibPrettyPrint_Formatter
local formatter = PrettyPrint:Formatter({ show_all = true, depth_limit = 3 })

-- Pooled inspector frames already hooked; they're reused.
local dragHooked = {}

--- @param inspector Frame
local function SaveInspectorPoint(inspector)
  local saved = ns:g().inspector
  saved.left, saved.bottom = inspector:GetLeft(), inspector:GetBottom()
end

--- Hooked after Blizzard's handler, so the drag has ended.
--- @param inspector Frame
local function TrackInspectorDrag(inspector)
  if dragHooked[inspector] then return end
  dragHooked[inspector] = true
  inspector.TitleButton:HookScript('OnDragStop', function()
    if ns:g().editor.rememberInspector then SaveInspectorPoint(inspector) end
  end)
end

--- At the saved point when remembered, else centered.
--- @param inspector Frame
local function PlaceInspector(inspector)
  local saved = ns:g().inspector
  local left, bottom = saved.left, saved.bottom
  inspector:ClearAllPoints()
  if ns:g().editor.rememberInspector and left and bottom then
    return PixelUtil.SetPoint(inspector, 'BOTTOMLEFT', UIParent, 'BOTTOMLEFT', left, bottom)
  end
  inspector:SetPoint('CENTER', UIParent)
end

--- Opens Blizzard's Table Inspector; a non-table prints a note.
--- @param value any
local function Inspect(value)
  if type(value) ~= 'table' then
    return print(L['inspect: expected a table, got %s']:format(type(value)))
  end
  C_AddOns.LoadAddOn('Blizzard_DebugTools')
  local inspector = DisplayTableInspectorWindow(value)
  TrackInspectorDrag(inspector)
  PlaceInspector(inspector)
end

--- Editor code sees these helpers, then _G; its global writes go to _G.
--- fs/fm/fv format single-line, multi-line, key=value; t logs to /etrace.
--- inspect (alias ti) opens the Table Inspector.
--- help prints the helpers list.
local env = setmetatable({
  -- Looked up per call: Exec swaps print while code runs.
  p = function(...) print(...) end,
  t = (TraceKit:New(ns.addon, 'CodeEditor', TRACE_COLOR, '_')),
  fm = formatter:MultiLine(),
  fs = formatter,
  fv = formatter:KeyValues(),
  inspect = Inspect,
  ti = Inspect,
  help = function() print(o:GetHelpText()) end,
}, { __index = _G, __newindex = _G })

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]

--- Space-joined, like WoW's own print; the writer colors it.
--- @param write LDK_OutputFn
local function Print(write, ...)
  local parts = {}
  for i = 1, select('#', ...) do
    parts[i] = tostring(select(i, ...))
  end
  write(table.concat(parts, ' '), 'print')
end

--- Keeps trailing nils that a plain { ... } would lose.
--- @return number?
--- @return any[]
local function Pack(...)
  return select('#', ...), { ... } --[[@as any[] ]]
end

--- A compile or runtime error; the writer colors it.
--- @param write LDK_OutputFn
--- @param msg any
local function WriteError(write, msg) write(tostring(msg), 'error') end

--- Runs func with print sent to write; reports a runtime error.
--- @param func function
--- @param write LDK_OutputFn
--- @return number? @Count of results, pcall's status included
--- @return any[]  @pcall's packed results; [1] is the status
local function Exec(func, write)
  setfenv(func, env)
  local oldPrint = print
  print = function(...) Print(write, ...) end
  local n, results = Pack(pcall(func))
  print = oldPrint
  if not results[1] then WriteError(write, results[2]) end
  return n, results
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]

--- @return string[][] @Each { signature, locale key }
--- @return string[]   @Example code; '--' lines show its output
function o:GetHelpers() return HELPERS, HELPERS_EXAMPLE end

--- The helpers list as plain text, signatures padded into a column.
--- @return string
function o:GetHelpText()
  local width = 0
  for _, helper in ipairs(HELPERS) do
    width = math.max(width, #helper[1])
  end
  local lines = { L['Editor Helpers'] }
  for _, helper in ipairs(HELPERS) do
    table.insert(lines, ('  %-' .. width .. 's  %s'):format(helper[1], L[helper[2]]))
  end
  table.insert(lines, '')
  for _, line in ipairs(HELPERS_EXAMPLE) do
    table.insert(lines, line)
  end
  return table.concat(lines, '\n')
end

--- Single-shot eval of one command line; no multi-line continuation.
--- REPL-style, like Lua 5.3+: tried as an expression first so its
--- values print, else run as a statement.
--- @param text string
--- @param write LDK_OutputFn
--- @return boolean @false on a compile or runtime error
function o:EvalCommand(text, write)
  -- '= expr' shorthand, same as WowLua's console.
  local src = text:match('^%s*=%s*(.+)$') or text
  local func = loadstring('return ' .. src)
  local isExpr = func ~= nil
  local err
  if not isExpr then
    func, err = loadstring(src)
  end

  if not func then
    WriteError(write, err)
    return false
  end

  local n, results = Exec(func, write)
  if results[1] and isExpr and n > 1 then Print(write, unpack(results, 2, n)) end
  return results[1]
end

--- Evaluates a whole code buffer as a Lua chunk; returned values
--- are ignored, like any normal chunk.
--- @param text string
--- @param write LDK_OutputFn
function o:EvalCode(text, write)
  local func, err = loadstring(text, 'Code Editor')
  if not func then return WriteError(write, err) end
  Exec(func, write)
end
