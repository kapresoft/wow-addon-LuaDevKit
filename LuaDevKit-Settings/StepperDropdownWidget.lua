--[[-----------------------------------------------------------------------------
StepperDropdown Widget
AceGUI select control using Blizzard's Settings dropdown with stepper arrows,
like DevSuite's. Use via `dialogControl = 'LuaDevKit_StepperDropdown'` on a
'select' option.
-------------------------------------------------------------------------------]]
local Type, Version = 'LuaDevKit_StepperDropdown', 1

--- @type LDK_Settings_Namespace
local ns = select(2, ...)
local cO = ns:cO()
local AceGUI, ACD = cO.AceGUI, cO.AceConfigDialog
if (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Label width matches SettingsCheckbox so the rows line up
local LAYOUT = {
  row = { height = 30 },
  label = { width = 210 },
  -- Width includes the stepper arrows
  dropdown = { width = 260, height = 30 },
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

--- @param list table<any, string>
--- @return any[] @Keys sorted by their display text
local function SortedKeys(list)
  local keys = {}
  for k in pairs(list) do
    table.insert(keys, k)
  end
  table.sort(keys, function(a, b) return tostring(list[a]) < tostring(list[b]) end)
  return keys
end

--- @param self table
local function SetupMenu(self)
  local function IsSelected(key) return key == self.value end
  local function SetSelected(key)
    if self.disabled or key == self.value then return end
    self.value = key
    self:Fire('OnValueChanged', key)
  end
  self.dropdown:SetupMenu(function(_, root)
    for _, key in ipairs(self.order) do
      root:CreateRadio(self.list[key], IsSelected, SetSelected, key)
    end
  end)
end

--- Blizzard uses TOOLTIP strata only if the owner has it
--- @param dropdown DropdownButton
local function OpenMenuAboveDialogs(dropdown)
  local openMenu = dropdown.OpenMenu
  function dropdown:OpenMenu()
    local strata = self:GetFrameStrata()
    self:SetFrameStrata('TOOLTIP')
    openMenu(self)
    self:SetFrameStrata(strata)
  end
end

--- @param self table
local function Refresh(self)
  if self.dropdown:IsShown() then self.dropdown:GenerateMenu() end
end

--- Arrow widths plus the gaps from Blizzard's OnLoad
--- @param control Frame
--- @return number @px
local function SteppersWidth(control)
  local back, forward = control.DecrementButton, control.IncrementButton
  local _, _, _, backX = back:GetPoint()
  local _, _, _, forwardX = forward:GetPoint()
  return back:GetWidth() - backX + forward:GetWidth() + forwardX
end

--- Same look as the hover highlight on Blizzard's Settings rows
--- @param frame Frame
--- @return Texture
local function CreateRowHighlight(frame)
  local hover = frame:CreateTexture(nil, 'BACKGROUND')
  hover:SetPoint('TOPLEFT', -10, 0)
  hover:SetPoint('BOTTOMRIGHT', -5, 0)
  hover:SetColorTexture(1, 1, 1, 0.1)
  hover:Hide()
  return hover
end

--- The option's `arg.layout.dropdown.width`, like DevSuite's
--- @param self table
--- @return number @px, stepper arrows included
local function DropdownWidth(self)
  local option = self:GetUserData('option')
  local arg = option and option.arg
  local layout = type(arg) == 'table' and arg.layout or {}
  local dropdown = layout.dropdown or {}
  return dropdown.width or LAYOUT.dropdown.width
end

--- Label column only; the control handles its own hover
--- @param self table
local function LimitHoverToLabel(self)
  local rightInset = math.max(0, self.frame:GetWidth() - LAYOUT.label.width)
  self.frame:SetHitRectInsets(0, rightInset, 0, 0)
end

--- Runs on each SetWidth; the option is only known by then
--- @param self table
local function ApplyLayout(self)
  local width = DropdownWidth(self)
  self.control:SetSize(width, LAYOUT.dropdown.height)
  self.dropdown:SetWidth(width - self.steppersWidth)
  LimitHoverToLabel(self)
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
--- @param self table
--- @param shown boolean
local function Frame_OnHover(self, shown)
  self.hover:SetShown(shown)
  if shown then
    FireEnter(self, self.label)
  else
    self:Fire('OnLeave')
  end
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
  OnAcquire = function(self)
    self.hover:Hide()
    self.list, self.order, self.value = {}, {}, nil
    self:SetWidth(200)
    self:SetDisabled(false)
  end,

  OnRelease = function(self)
    if self.dropdown.CloseMenu then self.dropdown:CloseMenu() end
    self.list, self.order, self.value = {}, {}, nil
  end,

  OnWidthSet = ApplyLayout,

  SetLabel = function(self, text) self.label:SetText(text) end,

  SetDisabled = function(self, disabled)
    self.disabled = disabled
    self.control:SetEnabled(not disabled)
    local color = disabled and GRAY_FONT_COLOR or NORMAL_FONT_COLOR
    self.label:SetTextColor(color:GetRGB())
  end,

  SetList = function(self, list, order)
    self.list = list or {}
    self.order = order or SortedKeys(self.list)
    Refresh(self)
  end,

  SetValue = function(self, value)
    self.value = value
    Refresh(self)
  end,

  GetValue = function(self) return self.value end,
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

  local template = 'LuaDevKit_DropdownWithSteppersTemplate' --[[@as Template ]]
  local control = CreateFrame('Frame', nil, frame, template)
  control:SetPoint('LEFT', label, 'RIGHT')

  local widget = {
    label = label,
    hover = CreateRowHighlight(frame),
    control = control,
    dropdown = control.Dropdown,
    steppersWidth = SteppersWidth(control),
    list = {},
    order = {},
    alignoffset = 30,
    frame = frame,
    type = Type,
  }
  for method, func in pairs(methods) do
    widget[method] = func
  end
  OpenMenuAboveDialogs(widget.dropdown)
  SetupMenu(widget)
  frame:SetScript('OnEnter', function() Frame_OnHover(widget, true) end)
  frame:SetScript('OnLeave', function() Frame_OnHover(widget, false) end)

  return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
