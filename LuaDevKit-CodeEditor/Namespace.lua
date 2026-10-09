--- @type string, table
local addon, xns = ...

--- CodeEditor addon reaches core only through this namespace.
--- @class LDK_CodeEditor_Namespace
--- @field addon Name
--- @field EXAMPLE_CODE string
--- @field O LDK_CodeEditor_Objects
local ns = xns
ns.addon = addon

--- @class LDK_CodeEditor_Objects
--- @field MinimalScrollBarStyle LDK_MinimalScrollBarStyle
local O = {}; ns.O = O

--- @return LDK_Core_Namespace, LDK_Core_Objects
function ns:cns() return LDK_CORE_NS, LDK_CORE_NS.O end

--- @return LDK_Core_Objects
function ns:cO() return self:cns().O end

--- @return LDK_DatabaseObj?
function ns:db() return self:cns():db() end

--- Call after DatabaseAccessMixin:InitDb().
--- @return LDK_DB_GlobalConfig
function ns:g() return self:cns():g() end

--- Call after DatabaseAccessMixin:InitDb().
--- @return LDK_DB_EditorConfig
function ns:editor() return self:g().editor end

--- Call after DatabaseAccessMixin:InitDb().
--- @return LDK_DB_ProfileConfig
function ns:p() return self:cns():p() end

--- Core's locale: the strings are registered under LuaDevKit.
--- @return table<string, string>
function ns:GetLocale() return self:cns():GetLocale() end

--- @param obj? table
--- @return AceEvent-3.0
function ns:NewAceEvent(obj) return self:cns():NewAceEvent(obj) end

--- @param editBox EditBox
function ns:EnableLuaFormatter(editBox) self:cns():EnableLuaFormatter(editBox) end

--- @param message Name
--- @return string @e.g. 'LuaDevKit-CodeEditor::OnEnable'
function ns:msg(message) return ('%s::%s'):format(self.addon, message) end
