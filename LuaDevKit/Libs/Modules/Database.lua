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
--- @field fontFamily? string @nil means Same as Editor
--- @field fontSize? number   @nil means Same as Editor

--- @class LDK_DB_GlobalConfig
--- @field editor LDK_DB_EditorConfig
--- @field console LDK_DB_ConsoleConfig

--- @class LDK_DB_ProfileConfig
--- @field documents LDK_Document[] @This profile's script workspace

--- @class LDK_DB_DefaultDatabase
--- @field global LDK_DB_GlobalConfig
--- @field profile LDK_DB_ProfileConfig

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- @class LDK_Database
local o = {}; O.Database = o

--- AceDB defaults; registered by DatabaseAccessMixin:InitDb(). Unset
--- settings fall back to the editor's own defaults.
--- @return LDK_DB_DefaultDatabase
function o:GetDefaultDatabase()
  return {
    ['global'] = {
      editor = {
        theme = THEME.DarkKnight,
      },
      console = {},
    },
    profile = {
      documents = {},
    },
  }
end
