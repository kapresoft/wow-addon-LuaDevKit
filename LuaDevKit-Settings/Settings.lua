--- @type LDK_Settings_Namespace
local ns = select(2, ...)
local cns, cO = ns:cns()
local L = ns:GetLocale()

-- AceConfig app name; also the window title.
local APP = 'LuaDevKit'

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
local registered = false

--- Both replace this profile's scripts; AceDBOptions only confirms Delete.
--- @param profiles table @AceDBOptions' options table
local function ConfirmOverwrites(profiles)
  local confirms = { reset = 'Reset Profile::Confirm', copyfrom = 'Copy From::Confirm' }
  for key, textKey in pairs(confirms) do
    profiles.args[key].confirm = true
    profiles.args[key].confirmText = L[textKey]
  end
end

--- On first open, like ABP's SettingsDialog: the AceDBOptions Profiles page.
local function RegisterOptions()
  if registered then return end
  registered = true
  local options = { type = 'group', name = APP, args = {} }
  options.args.profiles = cO.AceDBOptions:GetOptionsTable(ns:db())
  ConfirmOverwrites(options.args.profiles)
  cO.AceConfig:RegisterOptionsTable(APP, options)
end

--[[-----------------------------------------------------------------------------
AddOn: LuaDevKit-Settings
-------------------------------------------------------------------------------]]
local libName = ns.addon
--- @class LDK_Settings : AceAddon, AceEvent-3.0
local o = cO.AceAddon:NewAddon(libName, 'AceEvent-3.0'); LDK_Settings = o

--- Called once, after LuaDevKit (and its DB) and all addon files are loaded.
function o:OnInitialize()
  cns:Register('Settings', self)
  self:SendMessage(ns:msg('OnInitialize'))
end

function o:OnEnable() self:SendMessage(ns:msg('OnEnable'), self) end

function o:OnDisable() self:SendMessage(ns:msg('OnDisable'), self) end

--- Opens the settings window on the Profiles page.
function o:OpenProfiles()
  RegisterOptions()
  cO.AceConfigDialog:Open(APP)
  cO.AceConfigDialog:SelectGroup(APP, 'profiles')
end

--- @return LDK_Settings_Namespace
function o:ns() return ns end
