--- @type LDK_Core_Namespace
local ns = select(2, ...)
local O = ns.O
local THEME = O.Backdrops.theme

-- todo: handle profile-switch
-- todo: Save/Cancel/Discard prompt is ugly. Replace?
-- todo: Save Editor Anchor/Location (global)

--[[-----------------------------------------------------------------------------
Types
-------------------------------------------------------------------------------]]
--- @class LDK_DB_EditorConfig
--- @field theme? Name        @Unknown names fall back to the default = true theme
--- @field fontFamily? string @Key into FontUtil:GetFontChoices()
--- @field fontSize? number
--- @field wrapText? boolean
--- @field saveOnRun? boolean

--- @class LDK_DB_ConsoleConfig
--- @field fontFamily string                 @Font key, or SAME_AS_EDITOR_FONT
--- @field fontSize number                   @Or SAME_AS_EDITOR_SIZE
--- @field history LDK_CommandHistoryEntry[] @Oldest first

--- @class LDK_DB_GlobalConfig
--- @field editor LDK_DB_EditorConfig
--- @field console LDK_DB_ConsoleConfig
--- @field helpTipsDismissed table<string, boolean> @Keyed by tipKey; true once closed or its action is done

--- @class LDK_DB_ProfileConfig
--- @field docs LDK_Document[] @This profile's script workspace
--- @field docIndex number     @Last opened document; clamped on load
--- @field outputHeight number @Output panel height in UI units; clamped on show

--- @class LDK_DB_DefaultDatabase : AceDB.Schema
--- @field global LDK_DB_GlobalConfig
--- @field profile LDK_DB_ProfileConfig

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- Puts the default back for each saved value of the wrong type.
--- @param saved table
--- @param defaults table
local function RestoreMistyped(saved, defaults)
  for key, default in pairs(defaults) do
    local value = saved[key]
    if type(value) ~= type(default) then
      saved[key] = type(default) == 'table' and CopyTable(default) or default
    elseif type(value) == 'table' then
      RestoreMistyped(value, default)
    end
  end
end

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- @class LDK_Database
--- @field SAME_AS_EDITOR_FONT string @Console fontFamily that follows the editor
--- @field SAME_AS_EDITOR_SIZE number @Console fontSize that follows the editor
local o = {}; O.Database = o
o.SAME_AS_EDITOR_FONT = 'same-as-editor'
o.SAME_AS_EDITOR_SIZE = 0

--- @type LDK_DB_DefaultDatabase
local DEFAULT_DB = {
  ['global'] = {
    editor = {
      theme = THEME.DarkKnight,
      fontFamily = 'JetBrainsMono',
      fontSize = 12,
      saveOnRun = true,
    },
    console = {
      fontFamily = 'Inconsolata',
      fontSize = 10,
      history = {},
    },
    helpTipsDismissed = {},
  },
  profile = { docs = {}, docIndex = 1, outputHeight = 100 },
}

--- AceDB defaults; registered by DatabaseAccessMixin:InitDb(). Unset
--- settings fall back to the editor's own defaults.
--- @return LDK_DB_DefaultDatabase
function o:GetDefaultDatabase() return DEFAULT_DB end

--- Fixes hand-edited global settings; call after RegisterDefaults.
--- @param config LDK_DB_GlobalConfig
function o:Sanitize(config) RestoreMistyped(config, self:GetDefaultDatabase()['global']) end
