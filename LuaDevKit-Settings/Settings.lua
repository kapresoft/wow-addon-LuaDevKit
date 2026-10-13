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
  local reset, copy = profiles.args.reset, profiles.args.copyfrom
  reset.confirm = function(info)
    local name = NORMAL_FONT_COLOR:WrapTextInColorCode(info.handler:GetCurrentProfile())
    return L['Reset Profile::Confirm']:format(name)
  end
  copy.confirm = function(_, source)
    local name = NORMAL_FONT_COLOR:WrapTextInColorCode(source)
    return L['Copy From::Confirm']:format(name)
  end
end

--- A checkbox bound to global.editor[field].
--- @param field string
--- @param key string                 @Locale key of the label; key::Desc is its tooltip
--- @param order number
--- @param onSet? fun(value: boolean) @Applies the change to an open editor
--- @return table                     @AceConfig toggle
local function EditorCheckbox(field, key, order, onSet)
  local editor = cns:g().editor
  return {
    type = 'toggle',
    name = L[key],
    desc = L[key .. '::Desc'],
    order = order,
    width = 'full',
    dialogControl = 'LuaDevKit_SettingsCheckbox',
    get = function() return editor[field] end,
    set = function(_, value)
      editor[field] = value
      if onSet then onSet(value) end
    end,
  }
end

--- @param shown boolean
local function ShowToolbar(shown)
  local editor = cns:CodeEditor()
  if editor then editor:SetToolbarShown(shown) end
end

--- @param location LDK_OutputLocation
local function MoveOutput(location)
  local editor = cns:CodeEditor()
  if editor then editor:SetOutputLocation(location) end
end

--- A dropdown bound to global.editor.outputLocation.
--- @param order number
--- @return table @AceConfig select
local function OutputLocationSelect(order)
  local editor = cns:g().editor
  return {
    type = 'select',
    name = L['Output Panel'],
    desc = L['Output Panel::Desc'],
    order = order,
    values = { bottom = L['Bottom'], right = L['Right'] },
    sorting = { 'bottom', 'right' },
    get = function() return editor.outputLocation end,
    set = function(_, value)
      editor.outputLocation = value
      MoveOutput(value)
    end,
  }
end

--- @return table @AceConfig group, listed above Profiles
local function GeneralOptions()
  return {
    type = 'group',
    name = L['General'],
    order = 1,
    args = {
      openAtStartup = EditorCheckbox('openAtStartup', 'Open Editor at Startup', 1),
      showToolbar = EditorCheckbox('showToolbar', 'Show Toolbar', 2, ShowToolbar),
      outputLocation = OutputLocationSelect(3),
      saveOnRun = EditorCheckbox('saveOnRun', 'Save on Run', 4),
      escCloses = EditorCheckbox('escCloses', 'Escape Key Closes Editor', 5),
    },
  }
end

local function RegisterOptions()
  if registered then return end
  registered = true
  local options = { type = 'group', name = cns.addon, args = {} }
  options.args.general = GeneralOptions()
  options.args.profiles = cO.AceDBOptions:GetOptionsTable(ns:db())
  ConfirmOverwrites(options.args.profiles)
  cO.AceConfig:RegisterOptionsTable(cns.addon, options)
end

--- @param group 'general'|'profiles'
local function Show(group)
  RegisterOptions()
  cO.AceConfigDialog:Open(cns.addon)
  cO.AceConfigDialog:SelectGroup(cns.addon, group)
end

--- Refused in combat.
--- @param group 'general'|'profiles'
local function OpenGroup(group)
  if not InCombatLockdown() then return Show(group) end
  UIErrorsFrame:AddExternalErrorMessage(ERR_NOT_IN_COMBAT)
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

--- Opens the settings window on the General page; refused in combat.
function o:OpenGeneral() OpenGroup('general') end

--- Opens the settings window on the Profiles page; refused in combat.
function o:OpenProfiles() OpenGroup('profiles') end

--- Closes the settings window, or opens it on the General page.
function o:ToggleGeneral()
  if not self:IsOpen() then return self:OpenGeneral() end
  self:Close()
end

--- @return boolean
function o:IsOpen() return cO.AceConfigDialog.OpenFrames[cns.addon] ~= nil end

function o:Close() cO.AceConfigDialog:Close(cns.addon) end

--- Redraws an open settings window after a value changed elsewhere.
function o:Refresh() cO.AceConfigRegistry:NotifyChange(cns.addon) end

--- @return LDK_Settings_Namespace
function o:ns() return ns end
