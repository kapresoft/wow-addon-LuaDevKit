--- @type LDK_Core_Namespace
local ns = select(2, ...)
local O = ns.O
local THEME = O.Backdrops.theme

--[[-----------------------------------------------------------------------------
Types
-------------------------------------------------------------------------------]]
--- @class LDK_DB_EditorConfig
--- @field theme? Name        @Missing name falls back to the default = true theme
--- @field fontFamily? string @Key into FontUtil:GetFontChoices()
--- @field fontSize? number
--- @field wrapText? boolean

--- @class LDK_DB_ConsoleConfig
--- @field fontFamily string @Font key, or SAME_AS_EDITOR_FONT
--- @field fontSize number   @Or SAME_AS_EDITOR_SIZE

--- @class LDK_DB_GlobalConfig
--- @field editor LDK_DB_EditorConfig
--- @field console LDK_DB_ConsoleConfig

--- @class LDK_DB_ProfileConfig
--- @field docs LDK_Document[] @This profile's script workspace

--- @class LDK_DB_DefaultDatabase
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
local o = {}
O.Database = o
o.SAME_AS_EDITOR_FONT = 'same-as-editor'
o.SAME_AS_EDITOR_SIZE = 0

--- @type LDK_DB_DefaultDatabase
local DEFAULT_DB = {
  ['global'] = {
    editor = {
      theme = THEME.DarkKnight,
    },
    console = {
      fontFamily = 'Inconsolata',
      fontSize = 10,
    },
  },
  profile = { docs = {} },
}

-- todo: add a clear console below settings icon
-- todo: save docs
-- todo: remember divider position (profile)

--- AceDB defaults; registered by DatabaseAccessMixin:InitDb(). Unset
--- settings fall back to the editor's own defaults.
--- @return LDK_DB_DefaultDatabase
function o:GetDefaultDatabase() return DEFAULT_DB end

--- Fixes hand-edited global settings; call after RegisterDefaults.
--- @param config LDK_DB_GlobalConfig
function o:Sanitize(config) RestoreMistyped(config, self:GetDefaultDatabase()['global']) end
