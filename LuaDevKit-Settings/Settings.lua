--- @type LDK_Settings_Namespace
local ns = select(2, ...)
local cns, cO = ns:cns()
local L = ns:GetLocale()

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
  local options = { type = 'group', name = cns.addon, args = {} }
  options.args.profiles = cO.AceDBOptions:GetOptionsTable(ns:db())
  ConfirmOverwrites(options.args.profiles)
  cO.AceConfig:RegisterOptionsTable(cns.addon, options)
end

local function ShowProfiles()
  RegisterOptions()
  cO.AceConfigDialog:Open(cns.addon)
  cO.AceConfigDialog:SelectGroup(cns.addon, 'profiles')
end

--- Like ABP's ConfigDialogController; Ace's pooled window can't be reparented.
local function CloseOnCombat()
  local f = CreateFrame('Frame', nil, UIParent, 'SecureHandlerStateTemplate')
  f:SetScript('OnHide', function() cO.AceConfigDialog:Close(cns.addon) end)
  RegisterStateDriver(f, 'visibility', '[combat]hide; show')
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
  -- At load: a state driver can't be registered in combat.
  CloseOnCombat()
  self:SendMessage(ns:msg('OnInitialize'))
end

function o:OnEnable() self:SendMessage(ns:msg('OnEnable'), self) end

function o:OnDisable() self:SendMessage(ns:msg('OnDisable'), self) end

--- Opens the settings window on the Profiles page; refused in combat.
function o:OpenProfiles()
  if not InCombatLockdown() then return ShowProfiles() end
  UIErrorsFrame:AddExternalErrorMessage(ERR_NOT_IN_COMBAT)
end

--- @return LDK_Settings_Namespace
function o:ns() return ns end
