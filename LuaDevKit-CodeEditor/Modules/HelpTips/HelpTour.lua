--[[-----------------------------------------------------------------------------
HelpTour: picks which tour step a host dialog's help tip shows.

One tour per session: the first eligible tour with unseen steps owns the
session until /reload, even after it finishes. A step's close button or
its action (CompleteStep) advances to the next step.
@see TourList.lua
-------------------------------------------------------------------------------]]
--- @type LDK_CodeEditor_Namespace
local ns = select(2, ...)

--- @class LDK_HelpTourStep
--- @field key string                       @Key in global.helpTipsDismissed
--- @field textKey string                   @Locale key of the step text
--- @field anchor fun(host: Frame): Region? @Step is skipped while this is nil or hidden

--- @class LDK_HelpTourDef
--- @field id string
--- @field host string           @Host name passed to OnHostShown
--- @field since number?         @Feature tours only; nil means always eligible
--- @field steps LDK_HelpTourStep[]

--- @class LDK_HelpTourShowing
--- @field hostName string
--- @field host Frame
--- @field tip LDK_HelpTip
--- @field step LDK_HelpTourStep

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- @type LDK_HelpTourDef?
local sessionTour
--- @type LDK_HelpTourShowing?
local showing

--- @return table<string, boolean>
local function Dismissed() return ns:g().helpTipsDismissed end

--- @return number
local function HighestSince()
  local highest = 0
  for _, tour in ipairs(ns.O.TourList) do
    highest = math.max(highest, tour.since or 0)
  end
  return highest
end

--- Saved on the first open, so new users skip older feature tours.
--- @return number
local function Baseline()
  local g = ns:g()
  if not g.tourBaseline then g.tourBaseline = HighestSince() end
  return g.tourBaseline
end

--- @param tour LDK_HelpTourDef
--- @return boolean
local function IsEligible(tour) return tour.since == nil or tour.since > Baseline() end

--- @param tour LDK_HelpTourDef
--- @return boolean
local function HasUnseenStep(tour)
  for _, step in ipairs(tour.steps) do
    if not Dismissed()[step.key] then return true end
  end
  return false
end

--- @param tour LDK_HelpTourDef
--- @param host Frame
--- @return number? @nil if every unseen step's anchor is missing or hidden
local function FirstShowableStep(tour, host)
  for index, step in ipairs(tour.steps) do
    if not Dismissed()[step.key] then
      local anchor = step.anchor(host)
      if anchor and anchor:IsVisible() then return index end
    end
  end
end

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- @class LDK_HelpTour
local o = {}; ns.O.HelpTour = o

--- @param hostName string
--- @return LDK_HelpTourDef? @nil if another host's tour owns the session, or none is left
function o:SessionTour(hostName)
  if not sessionTour then
    for _, tour in ipairs(ns.O.TourList) do
      if tour.host == hostName and IsEligible(tour) and HasUnseenStep(tour) then
        sessionTour = tour
        break
      end
    end
  end
  return sessionTour and sessionTour.host == hostName and sessionTour or nil
end

--- Call from the host's OnShow; shows its next step or hides the tip.
--- @param hostName string
--- @param host Frame
--- @param tip LDK_HelpTip
function o:OnHostShown(hostName, host, tip)
  local tour = self:SessionTour(hostName)
  local index = tour and FirstShowableStep(tour, host)
  if not index then
    showing = nil
    tip:Hide()
    return
  end
  local step = tour.steps[index]
  showing = { hostName = hostName, host = host, tip = tip, step = step }
  tip.onClose = function() self:CompleteStep(step.key) end
  tip:ShowStep(step.textKey, step.anchor(host), index, #tour.steps)
end

--- Marks a step done, e.g. when the user does what it points at;
--- advances if it's the step on screen.
--- @param key string
function o:CompleteStep(key)
  Dismissed()[key] = true
  if not (showing and showing.step.key == key) then return end
  self:OnHostShown(showing.hostName, showing.host, showing.tip)
end
