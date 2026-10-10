--- @type LDK_Core_Namespace
local ns = select(2, ...)
local O = ns.O
local TU = O.TextUtil

--- @class LDK_OutputLine
--- @field text string
--- @field kind LDK_OutputKind?

--- @class LDK_OutputLog
--- @field maxLines number
--- @field lines LDK_OutputLine[]
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
--- @param kind LDK_OutputKind? @Colored by GetText; nil stays plain
function o:Append(text, kind)
  local lines = self.lines
  for line in TU:Lines(tostring(text or '')) do
    lines[#lines + 1] = { text = line, kind = kind }
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

--- Colored at read time, so a theme switch re-colors old lines.
--- @param colors table<LDK_OutputKind, ColorMixin>? @nil or a missing kind stays plain
--- @return string
function o:GetText(colors)
  local out = {}
  for i, line in ipairs(self.lines) do
    local color = colors and line.kind and colors[line.kind]
    out[i] = color and color:WrapTextInColorCode(line.text) or line.text
  end
  return table.concat(out, '\n')
end
