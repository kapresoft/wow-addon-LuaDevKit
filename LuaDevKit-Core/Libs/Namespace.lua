--- @type string, table
local addon, xns = ...

--- @class LDK_Core_Namespace
--- @field addon Name
local ns = xns; LDK_CORE_NS = ns
ns.addon = addon

print('Namespace', 'val=', ns)

--- @class LDK_Core_Objects
--- @field FAIAP? LuaDevKit-FAIAP-1-0
local O = {}; ns.O = O

ns.O.FAIAP = LibStub('LuaDevKit-FAIAP-1-0', true)

-- Lua syntax colorization, vendored from WowLua's FAIAP.lua. Runs before
-- SetText(SAMPLE_CODE) below so the first paint already goes through FAIAP's
-- SetText override; its GetText override returns decoded (uncolored) text, so
-- CountLines/RefreshGutter/wrap measuring all keep seeing clean source.
--
-- Known risk, not yet observed in practice: colorCodeEditbox() calls
-- indentEditbox() when the line count changes, and indentEditbox()'s write
-- guard compares color-STRIPPED text against its COLORED result, so it always
-- rewrites. If those two halves start invalidating each other's caches, this
-- will show up as continuous SetText/SetCursorPosition churn -- drop the
-- indentEditbox() call in colorCodeEditbox() if so, since only the colorize
-- half is wanted here.
--- @param editBox EditBox
function ns:EnableLuaFormatter(editBox)
  if not editBox or not self.O.FAIAP then return end

  local f = self.O.FAIAP
  -- todo: move to a config
  local COLOR_DEFS = {
    [f.tokens.TOKEN_KEYWORD]       = "|cffCF8E6D",  -- tan keywords
    [f.tokens.TOKEN_STRING]        = "|cffEFEFEF",  -- white strings
    [f.tokens.TOKEN_NUMBER]        = "|cff2AACB8",  -- teal numbers
    [f.tokens.TOKEN_COMMENT_SHORT] = "|cff7A7E85",  -- gray comments
    [f.tokens.TOKEN_COMMENT_LONG]  = "|cff7A7E85",  -- gray comments
    [f.tokens.TOKEN_IDENTIFIER]    = "|cff56B2FF",  -- light blue identifiers
    ["and"]                        = "|cffFFB9B0",  -- salmon
    ["or"]                         = "|cffFFB9B0",  -- salmon
    ["not"]                        = "|cffFFB9B0",  -- salmon
    [0] = "|r",                                     -- required: the stop code
  }
  f.enable(editBox, COLOR_DEFS)
end
