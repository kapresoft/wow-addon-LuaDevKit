--- @type LDK_CodeEditor_Namespace
local ns = select(2, ...)
local cO = ns:cO()
--- @type LDK_CodeEditorDialog
local dialog = LDK_CodeEditorDialog

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
  self:RegisterEvent('PLAYER_ENTERING_WORLD')
  self:SendMessage(ns:msg('OnEnable'), self)
  tr(libName, 'OnEnable', 'enabled=', self:IsEnabled())
end

function o:OnDisable()
  self:SendMessage(ns:msg('OnDisable'), self)
  tr(libName, 'OnDisable', 'enabled=', self:IsEnabled())
end

--- First fire is the login or reload; later ones are zoning.
function o:PLAYER_ENTERING_WORLD(evt)
  self:UnregisterEvent(evt)
  -- Silent in combat; Open() would show an error unprompted.
  if InCombatLockdown() then return end
  if ns:editor().openAtStartup then dialog:Open() end
end

--- @return LDK_CodeEditor_Namespace
function o:ns() return ns end
