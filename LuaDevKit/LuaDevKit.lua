--- @type LDK_Core_Namespace
local ns = select(2, ...)
local O = ns.O
local DatabaseMixin = O.DatabaseMixin

--[[-----------------------------------------------------------------------------
AddOn: LuaDevKit
-------------------------------------------------------------------------------]]
local libName = ns.addon
--- @class LuaDevKit : AceAddon, AceEvent-3.0, AceConsole-3.0, LDK_DatabaseMixin
local o = O.AceAddon:NewAddon(libName, 'AceEvent-3.0', 'AceConsole-3.0'); LDK = o

--[[-----------------------------------------------------------------------------
Methods: LuaDevKit
-------------------------------------------------------------------------------]]
--- Called once, after SavedVariables and all addon files are loaded.
function o:OnInitialize()
  DatabaseMixin:InitDb(self)
  self:SendMessage(ns:msg('OnInitialize'))
  tr(libName, 'OnInitialize', 'called')
end

function o:OnEnable()
  self:SendMessage(ns:msg('OnEnable'), self)
  tr(libName, 'OnEnable', 'enabled=', self:IsEnabled())
end

--- @return LDK_Core_Namespace
function o:ns() return ns end
