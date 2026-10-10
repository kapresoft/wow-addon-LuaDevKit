--[[-----------------------------------------------------------------------------
SettingsCheckbox Widget
AceGUI toggle control using Blizzard's Settings checkbox, like DevSuite's.
Use via `dialogControl = 'LuaDevKit_SettingsCheckbox'` on a 'toggle' option.
-------------------------------------------------------------------------------]]
local Type, Version = 'LuaDevKit_SettingsCheckbox', 1

--- @type LDK_Settings_Namespace
local ns = select(2, ...)
local cO = ns:cO()
local AceGUI, ACD = cO.AceGUI, cO.AceConfigDialog
if (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local LAYOUT = {
  row = { height = 30 },
  label = { width = 210 },
  checkbox = { width = 30, height = 30 },
  -- Tooltip BOTTOMLEFT offset from its context's TOPRIGHT
  tooltip = { x = 20, y = 20 },
}

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- Also moves AceConfigDialog's tooltip beside the context
--- @param widget table
--- @param context ScriptRegion
local function FireEnter(widget, context)
  widget:Fire('OnEnter')
  local tooltip = ACD.tooltip
  if not (tooltip and tooltip:IsShown() and tooltip:GetOwner() == widget.frame) then return end
  tooltip:SetAnchorType('ANCHOR_NONE')
  tooltip:ClearAllPoints()
  tooltip:SetPoint('BOTTOMLEFT', context, 'TOPRIGHT', LAYOUT.tooltip.x, LAYOUT.tooltip.y)
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
--- @param self table
local function Check_OnClick(self)
  local checked = self.check:GetChecked() and true or false
  local sound = checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
    or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
  PlaySound(sound)
  self.value = checked
  self:Fire('OnValueChanged', checked)
end

--- Uses the template's own HoverBackground as row highlight
--- @param self table
--- @param shown boolean
local function Frame_OnHover(self, shown)
  local hover = self.check.HoverBackground
  if hover then hover:SetShown(shown) end
  if shown then
    FireEnter(self, self.label)
  else
    self:Fire('OnLeave')
  end
end

--- Clicking the row toggles, like Blizzard's Settings rows
--- @param self table
local function Frame_OnMouseUp(self)
  if not self.disabled then self.check:Click() end
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
  OnAcquire = function(self)
    local hover = self.check.HoverBackground
    if hover then hover:Hide() end
    self:SetWidth(200)
    self:SetValue(false)
    self:SetDisabled(false)
  end,

  SetLabel = function(self, text) self.label:SetText(text) end,

  SetValue = function(self, value)
    self.value = value and true or false
    self.check:SetChecked(self.value)
  end,

  GetValue = function(self) return self.value end,

  SetDisabled = function(self, disabled)
    self.disabled = disabled
    self.check:SetEnabled(not disabled)
    local color = disabled and GRAY_FONT_COLOR or NORMAL_FONT_COLOR
    self.label:SetTextColor(color:GetRGB())
  end,

  -- AceConfigDialog calls these on every toggle; unsupported
  SetTriState = function() end,
  SetDescription = function() end,
  SetImage = function() end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
  local frame = CreateFrame('Frame', nil, UIParent)
  frame:EnableMouse(true)
  frame:SetHeight(LAYOUT.row.height)

  local label = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  label:SetPoint('LEFT')
  label:SetJustifyH('LEFT')
  label:SetWidth(LAYOUT.label.width)

  local template = 'SettingsCheckboxTemplate' --[[@as Template ]]
  local check = CreateFrame('CheckButton', nil, frame, template)
  check:SetPoint('LEFT', label, 'RIGHT')
  check:SetSize(LAYOUT.checkbox.width, LAYOUT.checkbox.height)

  local widget = {
    label = label,
    check = check,
    frame = frame,
    type = Type,
  }
  for method, func in pairs(methods) do
    widget[method] = func
  end

  check:SetScript('OnClick', function() Check_OnClick(widget) end)
  check:HookScript('OnEnter', function() FireEnter(widget, check) end)
  check:HookScript('OnLeave', function() widget:Fire('OnLeave') end)
  frame:SetScript('OnMouseUp', function() Frame_OnMouseUp(widget) end)
  frame:SetScript('OnEnter', function() Frame_OnHover(widget, true) end)
  frame:SetScript('OnLeave', function() Frame_OnHover(widget, false) end)

  return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
