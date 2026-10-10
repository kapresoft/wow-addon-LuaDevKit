--- @type LDK_Core_Namespace
local ns = select(2, ...)
local PrettyPrint, TraceKit = ns.O.LibPrettyPrint, ns.O.LibTraceKit

--- @alias LDK_OutputKind 'print'|'error'
--- @alias LDK_OutputFn fun(text: string, kind: LDK_OutputKind?)

--- @class LDK_LuaRunner
local o = {}; ns.O.LuaRunner = o

--- Strings in quotes; numbers, booleans and the rest via tostring.
--- @param value any
--- @return string
local function Literal(value)
  if type(value) == 'string' then return ("'%s'"):format(value) end
  return tostring(value)
end

--- One key=value line per entry, sorted; a non-table passes through.
--- @param value string|table
--- @return string
local function KeyValues(value)
  if type(value) ~= 'table' then return tostring(value) end
  local lines = {}
  for key, val in pairs(value) do
    lines[#lines + 1] = ('%s=%s'):format(tostring(key), Literal(val))
  end
  table.sort(lines)
  return table.concat(lines, '\n')
end

--- Editor code sees these helpers, then _G; its global writes go to _G.
--- f and fx match DevSuite's fmt and fmtx; t logs to /etrace.
local env = setmetatable({
  -- Looked up per call: Exec swaps print while code runs.
  p = function(...) print(...) end,
  t = (TraceKit:New(ns.addon, 'CodeEditor')),
  kv = KeyValues,
  f = PrettyPrint:Formatter({ show_all = true, depth_limit = 3 }),
  fx = PrettyPrint:Formatter({ show_all = true, depth_limit = 3, multiline_tables = true }),
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
--- @return number
--- @return any[]
local function Pack(...) return select('#', ...), { ... } end

--- A compile or runtime error; the writer colors it.
--- @param write LDK_OutputFn
--- @param msg any
local function WriteError(write, msg) write(tostring(msg), 'error') end

--- Runs func with print sent to write; reports a runtime error.
--- @param func function
--- @param write LDK_OutputFn
--- @return number @Count of results, pcall's status included
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
