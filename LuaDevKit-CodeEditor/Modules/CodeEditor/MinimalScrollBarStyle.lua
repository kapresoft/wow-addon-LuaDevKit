--[[-----------------------------------------------------------------------------
MinimalScrollBarStyle: restyles a legacy UIPanelScrollBar after
Blizzard's MinimalScrollBar (track, three-slice thumb, steppers).
-------------------------------------------------------------------------------]]
--- @type LDK_CodeEditor_Namespace
local ns = select(2, ...)

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
-- Gap between each stepper and the track the thumb runs in.
local ARROW_GAP = 4

-- Steppers, shrunk from the template's 18x16.
local ARROW_SCALE, ARROW_HEIGHT = 0.65, 11

-- Scrollbar thumb: three-slice art, sized by its own atlas.
local THUMB_ATLAS = 'minimal-scrollbar-small-thumb-'
local THUMB_SLICES = { 'top', 'middle', 'bottom' }

-- Track under the thumb; '!' tiles the middle.
local TRACK_ATLAS = {
  top = 'minimal-scrollbar-track-top',
  middle = '!minimal-scrollbar-track-middle',
  bottom = 'minimal-scrollbar-track-bottom',
}

--[[-----------------------------------------------------------------------------
Types
-------------------------------------------------------------------------------]]
--- @class LDK_MinimalScrollBarStyle
local o = {}; ns.O.MinimalScrollBarStyle = o

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- Groove the thumb runs in; spans the whole bar.
--- @param scrollBar Slider
local function StyleTrack(scrollBar)
  local slices = {}
  for _, slice in ipairs(THUMB_SLICES) do
    -- BACKGROUND: the thumb's ARTWORK slices draw over it.
    slices[slice] = scrollBar:CreateTexture(nil, 'BACKGROUND')
    slices[slice]:SetAtlas(TRACK_ATLAS[slice], true)
  end
  slices.top:SetPoint('TOP', scrollBar, 'TOP')
  slices.bottom:SetPoint('BOTTOM', scrollBar, 'BOTTOM')
  slices.middle:SetPoint('TOP', slices.top, 'BOTTOM')
  slices.middle:SetPoint('BOTTOM', slices.bottom, 'TOP')
end

--- Thumb art; a Slider thumb is one texture, so use three.
--- @param scrollBar Slider
local function StyleThumb(scrollBar)
  local thumb = scrollBar:GetThumbTexture()
  -- Art lives in the slices; the thumb only positions them.
  thumb:SetTexture(nil)

  local slices = {}
  for _, slice in ipairs(THUMB_SLICES) do
    slices[slice] = scrollBar:CreateTexture(nil, 'ARTWORK')
  end
  -- Centre: a Slider centres its thumb on the cross axis.
  slices.top:SetPoint('TOP', thumb, 'TOP')
  slices.bottom:SetPoint('BOTTOM', thumb, 'BOTTOM')
  slices.middle:SetPoint('TOP', slices.top, 'BOTTOM')
  slices.middle:SetPoint('BOTTOM', slices.bottom, 'TOP')

  local function SetState(suffix)
    for _, slice in ipairs(THUMB_SLICES) do
      slices[slice]:SetAtlas(THUMB_ATLAS .. slice .. suffix, true)
    end
  end
  SetState('')

  scrollBar:HookScript('OnEnter', function() SetState('-over') end)
  scrollBar:HookScript('OnLeave', function() SetState('') end)
  scrollBar:HookScript('OnMouseDown', function() SetState('-down') end)
  scrollBar:HookScript('OnMouseUp', function() SetState('') end)
end

--- Clear the template crop first; SetAtlas writes its own.
--- @param texture Texture|nil
--- @param atlas string
--- @param blendMode string|nil Template highlights are ADD; pass BLEND
local function SetArrowAtlas(texture, atlas, blendMode)
  if not texture then return end
  texture:SetTexCoord(0, 1, 0, 1)
  texture:SetAtlas(atlas, true)
  if blendMode then texture:SetBlendMode(blendMode) end
end

--- Pins a stepper just past its end of the track.
--- @param button Button
--- @param edge string 'top' or 'bottom'
local function AnchorArrow(button, edge)
  local point, relPoint, sign = 'BOTTOM', 'TOP', 1
  if edge == 'bottom' then point, relPoint, sign = 'TOP', 'BOTTOM', -1 end
  button:ClearAllPoints()
  -- Offsets are in button units; divide to hold the gap.
  button:SetPoint(point, button:GetParent(), relPoint, 0, sign * ARROW_GAP / button:GetScale())
end

--- Retextures a stepper with MinimalScrollBar atlases.
--- @param button Button
--- @param edge string 'top' or 'bottom'
--- @return number @Its footprint past the track end, in parent units
local function StyleArrow(button, edge)
  local atlas = 'minimal-scrollbar-arrow-' .. edge
  SetArrowAtlas(button:GetNormalTexture(), atlas)
  SetArrowAtlas(button:GetPushedTexture(), atlas .. '-down')
  SetArrowAtlas(button:GetHighlightTexture(), atlas .. '-over', 'BLEND')
  -- No disabled art; desaturate normal, as Blizzard does.
  SetArrowAtlas(button:GetDisabledTexture(), atlas)
  button:GetDisabledTexture():SetDesaturated(true)

  button:SetScale(ARROW_SCALE)
  button:SetHeight(ARROW_HEIGHT)
  AnchorArrow(button, edge)

  return button:GetHeight() * button:GetScale() + ARROW_GAP
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- Styles track, thumb and steppers of a UIPanelScrollBar.
--- @param scrollBar Slider
--- @return number up Top stepper footprint, in bar units
--- @return number down Bottom stepper footprint, in bar units
function o.Apply(scrollBar)
  StyleTrack(scrollBar)
  StyleThumb(scrollBar)
  -- Steppers sit outside the ends; style before anchoring.
  local up = StyleArrow(scrollBar.ScrollUpButton, 'top')
  local down = StyleArrow(scrollBar.ScrollDownButton, 'bottom')
  return up, down
end