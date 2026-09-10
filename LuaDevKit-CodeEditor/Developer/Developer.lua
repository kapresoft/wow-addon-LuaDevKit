local addon, ns = ...
local AceEvent = LibStub('AceEvent-3.0')

--- @class LDK_CodeEditor_Developer : AceEvent-3.0
local o = AceEvent:Embed({}); LDK_CodeEditor_Developer = o

--- @param isLogin boolean
--- @param isReload boolean
function o:PLAYER_ENTERING_WORLD(evt, isLogin, isReload)
  self:SendMessage('LDK_CodeEditor_Developer::READY', isLogin, isReload)
end

o:RegisterEvent('PLAYER_ENTERING_WORLD')