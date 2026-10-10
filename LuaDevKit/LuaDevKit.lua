--- @type LDK_Core_Namespace
local ns = select(2, ...)
local O = ns.O
local DatabaseAccessMixin = O.DatabaseAccessMixin
local L = ns:GetLocale()
local CMD_COLOR = CreateColorFromRGBHexString('FFE680')

--- @type { cmd: string, desc: string }[] @Slash subcommands, in display order
local slashCommands = {
  { cmd = 'info', desc = L['displays the addon info'] },
  { cmd = 'editor', desc = L['toggles the Code Editor'] },
  { cmd = 'settings', desc = L['toggles the settings window'] },
}

--[[-----------------------------------------------------------------------------
AddOn: LuaDevKit
-------------------------------------------------------------------------------]]
local libName = ns.addon
--- @class LuaDevKit : AceAddon, AceEvent-3.0, AceConsole-3.0, LDK_DatabaseAccess
local o = O.AceAddon:NewAddon(libName, 'AceEvent-3.0', 'AceConsole-3.0'); LDK = o

--[[-----------------------------------------------------------------------------
Methods: LuaDevKit
-------------------------------------------------------------------------------]]
--- Called once, after SavedVariables and all addon files are loaded.
function o:OnInitialize()
  DatabaseAccessMixin:InitDb(self)
  self:RegisterChatCommand('ldk', 'OnSlashCommand')
  self:SendMessage(ns:msg('OnInitialize'))
  tr(libName, 'OnInitialize', 'called')
end

function o:OnEnable()
  self:SendMessage(ns:msg('OnEnable'), self)
  tr(libName, 'OnEnable', 'enabled=', self:IsEnabled())
end

function o:PrintSlashCommandHelp()
  self:Print(L['Available commands:'])
  for _, c in ipairs(slashCommands) do
    self:Print(('  %s - %s'):format(CMD_COLOR:WrapTextInColorCode(c.cmd), c.desc))
  end
end

--- @param addon Name
function o:PrintRequires(addon) self:Print(L['Requires %s']:format(addon)) end

function o:ToggleEditor()
  local editor = ns:CodeEditor()
  if editor then return editor:Toggle() end
  self:PrintRequires('LuaDevKit-CodeEditor')
end

function o:ToggleSettings()
  local settings = ns:Settings()
  if settings then return settings:ToggleGeneral() end
  self:PrintRequires('LuaDevKit-Settings')
end

--- @param input string
function o:OnSlashCommand(input)
  local cmd = input:match('^(%S*)'):lower()
  if cmd == 'info' then
    self:Print(ns:aiu():GetInfoSlashCommandText())
  elseif cmd == 'editor' then
    self:ToggleEditor()
  elseif cmd == 'settings' then
    self:ToggleSettings()
  else
    self:PrintSlashCommandHelp()
  end
end

--- @return LDK_Core_Namespace
function o:ns() return ns end
