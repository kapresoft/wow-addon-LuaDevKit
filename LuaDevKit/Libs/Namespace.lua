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
local ns = xns; LDK_CORE_NS = ns
ns.addon, ns.options = addon, options

--- @class LDK_Core_Objects
--- @field FAIAP? LuaDevKit-FAIAP-1-0
--- @field LSM LibSharedMedia-3.0
--- @field FontUtil LDK_FontUtil
--- @field Backdrops LDK_Backdrops
--- @field Database LDK_Database
--- @field AceLocale AceLocale-3.0
--- @field String Kapresoft-String-2-0
--- @field Table Kapresoft-Table-2-0
local O = {}; ns.O = O

--- @param self LDK_Core_Objects
local function RegisterObjects(self)
  self.FAIAP = LibStub('LuaDevKit-FAIAP-1-0', true)
  self.LSM = LibStub('LibSharedMedia-3.0')
  self.String = LibStub('Kapresoft-String-2-0')
  self.Table = LibStub('Kapresoft-Table-2-0')
  self.AceLocale = LibStub('AceLocale-3.0')
end
RegisterObjects(O)

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

--- Enables Lua syntax colorization (WowLua's FAIAP) on the given EditBox.
--- @param editBox EditBox
function ns:EnableLuaFormatter(editBox)
  if not editBox or not self.O.FAIAP then return end

  local f = self.O.FAIAP
  -- todo: move to a config
  local COLOR_DEFS = {
    [f.tokens.TOKEN_KEYWORD] = '|cffCF8E6D', -- tan keywords
    [f.tokens.TOKEN_STRING] = '|cffEFEFEF', -- white strings
    [f.tokens.TOKEN_NUMBER] = '|cff2AACB8', -- teal numbers
    [f.tokens.TOKEN_COMMENT_SHORT] = '|cff9B9EA5', -- gray comments
    [f.tokens.TOKEN_COMMENT_LONG] = '|cff9B9EA5', -- gray comments
    [f.tokens.TOKEN_IDENTIFIER] = '|cff56B2FF', -- light blue identifiers
    ['and'] = '|cffFFB9B0', -- salmon
    ['or'] = '|cffFFB9B0', -- salmon
    ['not'] = '|cffFFB9B0', -- salmon
    [0] = '|r', -- required: the stop code
  }
  f.enable(editBox, COLOR_DEFS)
end
