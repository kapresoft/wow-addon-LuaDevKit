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
L['Double-click to maximize'] = true
L['Double-click to minimize'] = true
L['Maximize Output'] = true
L['Maximize Output::Desc'] = 'Expand the output panel to its largest size.'
L['Minimize Output'] = true
L['Minimize Output::Desc'] = 'Shrink the output panel to its smallest size.'
L['Theme'] = true
L['Theme::Desc'] = 'Choose the theme set for the editor.'
L['Font Family'] = true
L['Font Family::Desc'] = 'Choose the typeface used in the editor.'
L['Font Size'] = true
L['Font Size::Desc'] = 'Choose the editor font size.'
L['Increase Font Size'] = true
L['Increase Font Size::Desc'] = 'Step the editor font up to the next size.'
L['Decrease Font Size'] = true
L['Decrease Font Size::Desc'] = 'Step the editor font down to the previous size.'
L['Command Line'] = true
L['Command Line::Desc'] = 'Run a single line of Lua and print its result to the output panel.'
