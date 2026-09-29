--- @type LDK_Core_Namespace
local ns = select(2, ...)

--- @alias LDK_OutputFn fun(text: string)

--- @class LDK_LuaRunner
local o = {}; ns.O.LuaRunner = o

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- Grey, space-joined print output, matching WoW's own print.
--- @param write LDK_OutputFn
local function Print(write, ...)
  local parts = {}
  for i = 1, select('#', ...) do
    parts[i] = tostring(select(i, ...))
  end
  write('|cff999999' .. table.concat(parts, ' ') .. '|r')
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- Single-shot eval of one command line; no multi-line continuation.
--- @param text string
--- @param write LDK_OutputFn
function o:EvalCommand(text, write)
  -- '= expr' shorthand, same as WowLua's console.
  local expr = text:match('^%s*=%s*(.+)$')
  local func, err = loadstring(expr and ('print(' .. expr .. ')') or text)

  -- Not '= expr' syntax, but maybe still a bare expression -- retry the same
  -- way WowLua's console does, so e.g. typing "5 + 5" alone still prints.
  if not func and not expr then
    local retryFunc = loadstring('print(' .. text .. ')')
    if retryFunc then
      func, err = retryFunc, nil
    end
  end

  if not func then
    write('|cffff0000' .. err .. '|r')
    return
  end

  local oldPrint = print
  print = function(...) Print(write, ...) end
  local ok, runErr = pcall(func)
  print = oldPrint

  if not ok then write('|cffff0000' .. runErr .. '|r') end
end

--- Evaluates a whole code buffer as a Lua chunk.
--- @param text string
--- @param write LDK_OutputFn
function o:EvalCode(text, write)
  local func, err = loadstring(text, 'Code Editor')
  if not func then
    write('|cffff0000' .. err .. '|r')
    return
  end

  local oldPrint = print
  print = function(...) Print(write, ...) end
  local ok, runErr = pcall(func)
  print = oldPrint

  if not ok then write('|cffff0000' .. runErr .. '|r') end
end
