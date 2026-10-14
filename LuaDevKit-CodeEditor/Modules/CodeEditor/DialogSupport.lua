--[[-----------------------------------------------------------------------------
DialogSupport: helpers shared by CodeEditorDialog and its frame mixins.
-------------------------------------------------------------------------------]]
--- @type LDK_CodeEditor_Namespace
local ns = select(2, ...)
local L = ns:GetLocale()

--[[-----------------------------------------------------------------------------
Types
-------------------------------------------------------------------------------]]
--- @class LDK_DialogSupport
local o = {}; ns.O.DialogSupport = o

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- @param frame Frame
--- @param key string                     @Locale key of the label; the description is key .. '::Desc'
--- @param hintKey (fun(): string?) | nil @Returns a locale key for a green instruction line, or nil for none
local function ShowTooltip(frame, key, hintKey)
  GameTooltip_SetDefaultAnchor(GameTooltip, frame)
  GameTooltip_SetTitle(GameTooltip, L[key])
  GameTooltip_AddNormalLine(GameTooltip, L[key .. '::Desc'])
  local hint = hintKey and hintKey()
  if hint then GameTooltip_AddInstructionLine(GameTooltip, L[hint]) end
  GameTooltip:Show()
end

--- Standard hover tooltip; hooked so it composes with a frame's own OnEnter.
--- @param frame Frame
--- @param key string                     @Locale key of the label; the description is key .. '::Desc'
--- @param hintKey (fun(): string?) | nil @Re-evaluated on every show; see ShowTooltip
--- @return fun()                         @Redraws the tooltip if it is showing for frame
function o.AddTooltip(frame, key, hintKey)
  local function show() ShowTooltip(frame, key, hintKey) end
  frame:HookScript('OnEnter', show)
  frame:HookScript('OnLeave', function() GameTooltip:Hide() end)
  return function()
    if GameTooltip:IsOwned(frame) then show() end
  end
end
