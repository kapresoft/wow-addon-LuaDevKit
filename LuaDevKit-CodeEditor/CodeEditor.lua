--- @type LDK_CodeEditor_Namespace
local ns = select(2, ...)
local _, cO = ns:cns()

--[[-----------------------------------------------------------------------------
AddOn: LuaDevKit-CodeEditor
-------------------------------------------------------------------------------]]
local libName = ns.addon
--- @class LDK_CodeEditor : AceAddon, AceEvent-3.0
local o = cO.AceAddon:NewAddon(libName, 'AceEvent-3.0'); LDK_CodeEditor = o

--[[-----------------------------------------------------------------------------
Methods: LDK_CodeEditor
-------------------------------------------------------------------------------]]
--- Called once, after LuaDevKit and all addon files are loaded.
function o:OnInitialize()
  self:SendMessage(ns:msg('OnInitialize'))
  tr(libName, 'OnInitialize', 'called')
end

function o:OnEnable()
  self:SendMessage(ns:msg('OnEnable'), self)
  tr(libName, 'OnEnable', 'enabled=', self:IsEnabled())
end

function o:OnDisable()
  self:SendMessage(ns:msg('OnDisable'), self)
  tr(libName, 'OnDisable', 'enabled=', self:IsEnabled())
end

--- @return LDK_CodeEditor_Namespace
function o:ns() return ns end
