--- @diagnostic disable: inject-field

--- @type LDK_Core_Namespace
local ns = select(2, ...)

--- @type AceLocale-3.0
local L = ns.O.AceLocale:NewLocale(ns.addon, 'enUS', true, ns.options.ignoreMissingKeys)
if not L then return end

-- Label/description pairs: the label key is the short text itself (= true),
-- and 'Label::Desc' holds its longer tooltip description.
L['Wrap Text'] = true
L['Wrap Text::Desc'] = 'Wrap long lines to fit the editor width instead of scrolling sideways.'
L['Resize Output'] = true
L['Resize Output::Desc'] =
  'Drag to resize the output panel. Use the arrows to maximize or minimize it.'
L['Maximize Output'] = true
L['Maximize Output::Desc'] = 'Expand the output panel to its largest size.'
L['Minimize Output'] = true
L['Minimize Output::Desc'] = 'Shrink the output panel to its smallest size.'
