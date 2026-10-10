--[[-----------------------------------------------------------------------------
TourList: every help tour, in priority order.

Tours without `since` are always eligible (the welcome tour). Feature tours
set `since` one past the highest in use, so only users who installed before
it see them. Step keys must be unique across all tours.
@see HelpTour.lua
-------------------------------------------------------------------------------]]
--- @type LDK_CodeEditor_Namespace
local ns = select(2, ...)

--- @type LDK_HelpTourDef[]
ns.O.TourList = {
  {
    id = 'welcome',
    host = 'CodeEditor',
    steps = {
      {
        key = 'OptionsMenu',
        textKey = 'Options::HelpTip',
        --- @param d LDK_CodeEditorDialog
        anchor = function(d) return d.Header.OptionsButton end,
      },
      {
        key = 'RunButton',
        textKey = 'Run::HelpTip',
        --- @param d LDK_CodeEditorDialog
        anchor = function(d) return d.StatusDivider.RunButton end,
      },
      {
        key = 'CommandLine',
        textKey = 'Command Line::HelpTip',
        --- @param d LDK_CodeEditorDialog
        anchor = function(d) return d.CommandEditBox end,
      },
      {
        key = 'CommandHistory',
        textKey = 'Command History::HelpTip',
        --- @param d LDK_CodeEditorDialog
        anchor = function(d) return d.HistoryButton end,
      },
    },
  },
}
