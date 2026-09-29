--- @type LDK_Core_Namespace
local ns = select(2, ...)
local O = ns.O
local TU = O.TextUtil

--- @class LDK_OutputLog
--- @field maxLines number
--- @field lines string[]
local o = {}; O.OutputLog = o

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- @param maxLines number @Oldest lines drop past this
--- @return LDK_OutputLog
function o:New(maxLines) return CreateAndInitFromMixin(o, maxLines) end

--- @param maxLines number
function o:Init(maxLines)
  self.maxLines = maxLines
  self.lines = {}
end

--- Drops every line collected so far.
function o:Clear() self.lines = {} end

--- Appends text; embedded newlines count toward the cap.
--- @param text string
function o:Append(text)
  local lines = self.lines
  for line in TU:Lines(tostring(text or '')) do
    lines[#lines + 1] = line
  end
  local excess = #lines - self.maxLines
  if excess > 0 then
    -- Shift survivors down instead of rebuilding the table each append.
    for i = 1, #lines - excess do
      lines[i] = lines[i + excess]
    end
    for i = #lines - excess + 1, #lines do
      lines[i] = nil
    end
  end
end

--- @return string
function o:GetText() return table.concat(self.lines, '\n') end
