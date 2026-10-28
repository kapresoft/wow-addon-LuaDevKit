--[[-----------------------------------------------------------------------------
For LuaDevKit Editor: run with the editor open.

Drives the Code Editor's real welcome tour through its tip's own buttons.
Uses the real saved data: each test first clears the tour's dismissed steps.
TestSkip leaves the tour skipped; /reload, then run TestStaysSkipped.
-------------------------------------------------------------------------------]]
local editor = LDK_CodeEditorDialog
local STEP_KEYS = { 'OptionsMenu', 'RunButton', 'CommandLine', 'CommandHistory' }

--- @param label string
--- @param ok boolean
local function Check(label, ok) print(ok and '|cff00ff00PASS|r' or '|cffff0000FAIL|r', label) end

--- @return table<string, boolean>
local function Dismissed() return LDK_CORE_NS:g().helpTipsDismissed end

local function ResetTour()
  local dismissed = Dismissed()
  for _, key in ipairs(STEP_KEYS) do
    dismissed[key] = nil
  end
end

--- @return boolean
local function AllDismissed()
  local dismissed = Dismissed()
  for _, key in ipairs(STEP_KEYS) do
    if not dismissed[key] then return false end
  end
  return true
end

--- @return LibHelpTour_Tip? @nil until the tour first shows
local function FindTip()
  for _, child in ipairs({ editor:GetChildren() }) do
    if child.SkipButton then return child end
  end
end

--- Re-runs the editor's OnShow, which asks the tour for its next step.
--- @return LibHelpTour_Tip?
local function ShowTour()
  editor:OnShow()
  return FindTip()
end

--- Skip on every step but the last; Close walks to the end.
local function TestWalk()
  ResetTour()
  local tip = ShowTour()
  Check('tip shows', tip ~= nil and tip:IsShown())
  if not tip then return end
  -- Bounded: a Close that fails to advance can't loop forever
  for _ = 1, #STEP_KEYS do
    if not tip:IsShown() then break end
    local step = tip.Counter:GetText()
    local isLast = step:match('^(%d+)/%1$') ~= nil
    Check(step .. ': Skip ' .. (isLast and 'hidden' or 'shown'), tip.SkipButton:IsShown() ~= isLast)
    tip.CloseButton:Click()
  end
  Check('tour finished', not tip:IsShown())
  Check('every step dismissed', AllDismissed())
end

--- Skip hides the tip and dismisses every step.
local function TestSkip()
  ResetTour()
  local tip = ShowTour()
  Check('Skip shown on the first step', tip ~= nil and tip.SkipButton:IsShown())
  if not tip then return end
  tip.SkipButton:Click()
  Check('tip hidden after Skip', not tip:IsShown())
  Check('every step dismissed', AllDismissed())
end

--- Run after TestSkip and a /reload: the skip was saved.
local function TestStaysSkipped()
  Check('every step still dismissed', AllDismissed())
  local tip = ShowTour()
  Check('no tip on show', not (tip and tip:IsShown()))
end

TestWalk()
--TestSkip()
--TestStaysSkipped()
