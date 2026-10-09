--- @type LDK_CodeEditor_Namespace
local ns = select(2, ...)
local L = ns:GetLocale()

-- Centers the arrow over the target.
local ARROW_OFFSET_X = 34
-- Same for ArrowUp, which sits left of the close button.
local ARROW_UP_OFFSET_X = 66
-- Tip edge to target edge; leaves room for the arrow.
local ARROW_GAP = 19
-- Text's left inset plus room for the close button.
local TEXT_PAD_X = 44
local TEXT_PAD_Y = 32

--[[-----------------------------------------------------------------------------
LDK_HelpTipMixin
@see HelpTips.xml
-------------------------------------------------------------------------------]]
--- @class LDK_HelpTipMixin : Frame
--- @field Text FontString
--- @field CloseButton Button
--- @field Arrow Frame         @Points down; shown while the tip is above its target
--- @field ArrowUp Frame       @Points up; shown while the tip is below its target
--- @field tipKey string       @Key in global.helpTipsDismissed; set per instance in XML
--- @field textKey string      @Locale key of the tip text; set per instance in XML
--- @field textMaxWidth number @Wrap width; Text's width from XML
LDK_HelpTipMixin = {}; local o = LDK_HelpTipMixin

--
--- @class LDK_HelpTip : LDK_HelpTipMixin
--

function o:OnLoad()
  self.textMaxWidth = self.Text:GetWidth()
  self.Text:SetText(L[self.textKey])
  self.CloseButton:SetScript('OnClick', function() self:Dismiss() end)
end

--- Points at anchorTo unless this tip was dismissed before.
--- @param anchorTo Region
function o:ShowOnce(anchorTo)
  -- todo: if we have more than one tips to show, we should make sure we only show one at a time
  --       Example: show tip #1, if dismissed by user, then next reload shows tip #2, else keep showing tip #1
  if ns:g().helpTipsDismissed[self.tipKey] then
    self:Hide()
    return
  end

  -- Set here: the parent raises its level after our OnLoad.
  self:SetFrameLevel(self:GetParent():GetFrameLevel() + 10)
  self:FitToText()
  self:PlaceAt(anchorTo)
  self:Show()
end

--- Short text shrinks the box; long text wraps at textMaxWidth.
function o:FitToText()
  local text = self.Text
  local width = math.min(text:GetUnboundedStringWidth(), self.textMaxWidth)
  text:SetWidth(width)
  self:SetSize(width + TEXT_PAD_X, text:GetHeight() + TEXT_PAD_Y)
end

--- Above anchorTo when it fits on screen, else below with the arrow flipped.
--- @param anchorTo Region
function o:PlaceAt(anchorTo)
  local below = self:RoomAbove(anchorTo) < ARROW_GAP + self:GetHeight()
  self.Arrow:SetShown(not below)
  self.ArrowUp:SetShown(below)
  self:ClearAllPoints()
  if below then
    self:SetPoint('TOPRIGHT', anchorTo, 'BOTTOM', ARROW_UP_OFFSET_X, -ARROW_GAP)
  else
    self:SetPoint('BOTTOMRIGHT', anchorTo, 'TOP', ARROW_OFFSET_X, ARROW_GAP)
  end
end

--- @param anchorTo Region
--- @return number @Space between anchorTo's top and the screen top, in this tip's units
function o:RoomAbove(anchorTo)
  local screenTop = UIParent:GetTop() * UIParent:GetEffectiveScale()
  local anchorTop = anchorTo:GetTop() * anchorTo:GetEffectiveScale()
  return (screenTop - anchorTop) / self:GetEffectiveScale()
end

function o:Dismiss()
  self:Hide()
  ns:g().helpTipsDismissed[self.tipKey] = true
end
