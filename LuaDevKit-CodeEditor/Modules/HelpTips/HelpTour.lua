--[[-----------------------------------------------------------------------------
HelpTour: the Code Editor's LibHelpTour controller.

Keeps the saved fields the editor used before the library, so existing users
don't see tours again.
@see TourList.lua
-------------------------------------------------------------------------------]]
--- @type LDK_CodeEditor_Namespace
local ns = select(2, ...)
local L = ns:GetLocale()
local TourList = ns.O.TourList
local HelpTourLib = LibStub('LibHelpTour-1.0')

ns.O.HelpTour = HelpTourLib:New({
  tours = TourList,
  dismissed = function() return ns:g().helpTipsDismissed end,
  getBaseline = function() return ns:g().tourBaseline end,
  setBaseline = function(baseline) ns:g().tourBaseline = baseline end,
  text = function(textKey) return L[textKey] end,
})
