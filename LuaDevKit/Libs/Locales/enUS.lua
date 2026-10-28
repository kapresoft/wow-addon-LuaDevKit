--- @diagnostic disable: inject-field

--- @type LDK_Core_Namespace
local ns = select(2, ...)

--- @type AceLocale-3.0
local L = ns.O.AceLocale:NewLocale(ns.addon, 'enUS', true, ns.options.ignoreMissingKeys)
if not L then return end

L['LuaDevKit Code Editor'] = true

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
L['Command Line::HelpTip'] = 'Run one line of Lua here'
L['Command History'] = true
L['Command History::Desc'] = 'Pick a previous command to put it back on the command line.'
L['Command History::HelpTip'] = 'Pick a recent command here'
L['No Command History'] = true
L['Console Settings'] = true
L['Console Settings::Desc'] = 'Choose the font and size of the output panel and command line.'
L['Console Font'] = true
L['Console Font Size'] = true
L['Same as Editor'] = true
L['Clear Output'] = true
L['Clear Output::Desc'] = 'Remove all text from the output panel.'
L['Editor Helpers'] = true
L['Editor Helpers::Desc'] = 'Built-in functions for code in the editor and on the command line.'
L['Editor Helpers::p'] = 'Print to the output panel'
L['Editor Helpers::t'] = 'Trace to /etrace'
L['Editor Helpers::fm'] = 'Format a value across indented lines'
L['Editor Helpers::fs'] = 'Format a value on one line'
L['Editor Helpers::fv'] = "Show a table's keys and values as key=value pairs"
L['Editor Helpers::inspect'] = "Evaluate <val> in Blizzard's Table Inspector"
L['Editor Helpers::help'] = 'Print this list'
L['inspect: expected a table, got %s'] = true
L['Editor Helpers::Hint'] = 'Click to print this list to the output panel'
L['Run'] = true
L['Run::Desc'] = 'Run the code in the editor and print its output to the output panel.'
L['Run::Hint'] = 'Ctrl+1 to run while cursor is in editor'
L['Run::Hint::Mac'] = 'Cmd+1 to run while cursor is in editor'
L['Run::HelpTip'] = 'Run your code'
L['New Document'] = true
L['New Document::Desc'] = 'Start a new, empty Lua document.'
L['Save Document'] = true
L['Save Document::Desc'] = 'Save this document.'
L['Save Document::Hint'] = 'No unsaved changes'
L['Delete Document'] = true
L['Delete Document::Desc'] = 'Delete this document.'
L['Delete "%s"?'] = true
L['Delete'] = true
L['Open Document'] = true
L['Open Document::Desc'] = 'Switch to another document; the arrows step through them.'
L['Open Document::Hint'] = 'Shift-click to rename\nAlt-click to save as a new document'
L['Rename Document'] = true
L['Save Document As'] = true
L['%s Copy'] = true
L['Untitled'] = true
L['Show Toolbar'] = true
L['Show Toolbar::Desc'] = 'Show the toolbar above the code area.'
L['Options::HelpTip'] = 'More options here'
L['Skip Tour'] = true
L['Save on Run'] = true
L['Save on Run::Desc'] = 'Save the document each time you run it.'
L['Output Panel'] = true
L['Output Panel::Desc'] = 'Show the output panel below the code or to its right.'
L['Output Panel::Hint::Right'] = 'Click to move it to the right'
L['Output Panel::Hint::Bottom'] = 'Click to move it to the bottom'
L['Bottom'] = true
L['Right'] = true
L['Profile'] = true
L['This'] = true
L['Manage Profiles...'] = true
L['Requires %s'] = true
L['Reset Profile::Confirm'] =
  "Reset %s? All documents in this profile will be deleted. This can't be undone."
L['Copy From::Confirm'] =
  "Copy documents from %s? All documents in this profile will be replaced. This can't be undone."
L['Save changes to "%s"?'] = true
L['Save'] = true
L['Cancel'] = true
L['Discard'] = true
L['General'] = true
L['Open Editor at Startup'] = true
L['Open Editor at Startup::Desc'] = 'Open the Code Editor when you log in or reload the UI.'
L['Escape Key Closes Editor'] = true
L['Escape Key Closes Editor::Desc'] =
  'Press Escape to close the Code Editor. If the settings window is open, Escape closes it first.'
L["Remember Blizzard's Table Inspector Location"] = true
L["Remember Blizzard's Table Inspector Location::Desc"] =
  'Open the Table Inspector from inspect() or ti() where you last moved it, instead of centered.'
L['Available commands:'] = true
L['displays the addon info'] = true
L['toggles the Code Editor'] = true
L['toggles the settings window'] = true
