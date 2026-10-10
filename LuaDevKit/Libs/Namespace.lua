local libName = 'LDK_Core_Namespace'

--- @type string, table
local addon, xns = ...

--- @class LDK_Core_Options
--- @field ignoreMissingKeys boolean

--- @type LDK_Core_Options
local options = {
  ignoreMissingKeys = true,
}

--- @class LDK_Core_Namespace
--- @field addon Name
--- @field options LDK_Core_Options
--- @field DB_NAME Name           @SavedVariables name; matches LuaDevKit.toc
--- @field dbObj? LDK_DatabaseObj @nil until DatabaseAccessMixin:InitDb()
local ns = xns; LDK_CORE_NS = ns
ns.addon, ns.options = addon, options
ns.DB_NAME = 'LUADEVKIT_DB'

--- @class LDK_Core_Objects
--- @field FAIAP? LuaDevKit-FAIAP-1-0
--- @field LSM LibSharedMedia-3.0
--- @field FontUtil LDK_FontUtil
--- @field Themes LDK_Themes
--- @field Database LDK_Database
--- @field DatabaseAccessMixin LDK_DatabaseAccessMixin
--- @field LuaRunner LDK_LuaRunner
--- @field TextUtil LDK_TextUtil
--- @field OutputLog LDK_OutputLog
--- @field DocumentStore LDK_DocumentStore
--- @field AceAddon AceAddon-3.0
--- @field AceConfig AceConfig-3.0
--- @field AceConfigDialog AceConfigDialog-3.0
--- @field AceDB AceDB-3.0
--- @field AceDBOptions AceDBOptions-3.0
--- @field AceEvent AceEvent-3.0
--- @field AceLocale AceLocale-3.0
--- @field String Kapresoft-String-2-0
--- @field Table Kapresoft-Table-2-0
--- @field Settings LDK_Settings? @Set when LuaDevKit-Settings loads; use ns:Settings()
local O = {}; ns.O = O

--- @param self LDK_Core_Objects
local function RegisterObjects(self)
  self.FAIAP = LibStub('LuaDevKit-FAIAP-1-0', true)
  self.LSM = LibStub('LibSharedMedia-3.0')
  self.String = LibStub('Kapresoft-String-2-0')
  self.Table = LibStub('Kapresoft-Table-2-0')
  self.AceAddon = LibStub('AceAddon-3.0')
  self.AceConfig = LibStub('AceConfig-3.0')
  self.AceConfigDialog = LibStub('AceConfigDialog-3.0')
  self.AceDB = LibStub('AceDB-3.0')
  self.AceDBOptions = LibStub('AceDBOptions-3.0')
  self.AceEvent = LibStub('AceEvent-3.0')
  self.AceLocale = LibStub('AceLocale-3.0')
end
RegisterObjects(O)

--- Register a Namespace Module
--- @generic T
--- @param lib Name   @The library name
--- @param anyObj? T @The library object instance; a new {} if nil
--- @return T
function ns:Register(lib, anyObj)
  assertsafe(
    type(lib) == 'string' and (anyObj == nil or type(anyObj) == 'table'),
    'Register(lib, anyObj): <lib> should be a string (got %s); <anyObj> a table or nil (got %s).',
    type(lib),
    type(anyObj)
  )
  local obj = anyObj or {}
  self.O[lib] = obj
  return obj
end

--- @param db LDK_DatabaseObj
function ns:RegisterDB(db) self.dbObj = db end

--- @return LDK_DatabaseObj?
function ns:db() return self.dbObj end

--- Call after DatabaseAccessMixin:InitDb().
--- @return LDK_DB_GlobalConfig
function ns:g() return self:db()['global'] end

--- Call after DatabaseAccessMixin:InitDb().
--- @return LDK_DB_ProfileConfig
function ns:p() return self:db().profile end

--- @return AceEvent-3.0
function ns:AceEvent() return self.O.AceEvent end

--- @return LDK_Settings? @nil when LuaDevKit-Settings isn't loaded or is disabled
function ns:Settings()
  local settings = self.O.Settings
  return settings and settings:IsEnabled() and settings or nil
end

--- Embeds AceEvent into obj, or into a new table when nil.
--- @param obj? table
--- @return AceEvent-3.0
function ns:NewAceEvent(obj) return self:AceEvent():Embed(obj or {}) end

--- @param message Name
--- @return string @e.g. 'LuaDevKit::OnEnable'
function ns:msg(message) return ('%s::%s'):format(self.addon, message) end

--- @return table<string, string>
function ns:GetLocale()
  return self.O.AceLocale:GetLocale(self.addon, self.options.ignoreMissingKeys)
end

--- For non-enUS locales only; always registers with isDefault=false, silent=true.
--- @see AceLocale-3.0.NewLocale
--- @param locale string
--- @return table<string, boolean|string>? locale Locale Table to add localizations to, or nil if the current locale is not required.
function ns:NewLocale(locale)
  return self.O.AceLocale:NewLocale(self.addon, locale, false, self.options.ignoreMissingKeys)
end

--- FAIAP's color table for the given syntax colors.
--- @param syntax LDK_SyntaxColors @Every kind set, as Themes:GetTheme() resolves it
--- @return table? @nil if FAIAP isn't loaded
function ns:LuaColorTable(syntax)
  local f = self.O.FAIAP
  if not f then return nil end
  local t = f.tokens
  local function c(hex) return '|cff' .. hex end
  return {
    [t.TOKEN_KEYWORD] = c(syntax.keyword),
    [t.TOKEN_STRING] = c(syntax.string),
    [t.TOKEN_NUMBER] = c(syntax.number),
    [t.TOKEN_COMMENT_SHORT] = c(syntax.comment),
    [t.TOKEN_COMMENT_LONG] = c(syntax.comment),
    [t.TOKEN_IDENTIFIER] = c(syntax.identifier),
    ['and'] = c(syntax.logical),
    ['or'] = c(syntax.logical),
    ['not'] = c(syntax.logical),
    [0] = '|r', -- required: the stop code
  }
end

--- Enables Lua syntax colorization (WowLua's FAIAP) on the given EditBox;
--- calling it again re-colors with the new syntax colors.
--- @param editBox EditBox
--- @param syntax LDK_SyntaxColors
function ns:EnableLuaFormatter(editBox, syntax)
  local colors = editBox and self:LuaColorTable(syntax)
  if not colors then return end
  self.O.FAIAP.enable(editBox, colors)
end
