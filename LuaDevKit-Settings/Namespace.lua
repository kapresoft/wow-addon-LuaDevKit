--- @type string, table
local addon, xns = ...

--- Settings addon reaches core only through this namespace.
--- @class LDK_Settings_Namespace
--- @field addon Name
local ns = xns
ns.addon = addon

--- @return LDK_Core_Namespace, LDK_Core_Objects
function ns:cns() return LDK_CORE_NS, LDK_CORE_NS.O end

--- @return LDK_Core_Objects
function ns:cO() return self:cns().O end

--- @return LDK_DatabaseObj?
function ns:db() return self:cns():db() end

--- Core's locale: the strings are registered under LuaDevKit.
--- @return table<string, string>
function ns:GetLocale() return self:cns():GetLocale() end

--- @param message Name
--- @return string @e.g. 'LuaDevKit-Settings::OnEnable'
function ns:msg(message) return ('%s::%s'):format(self.addon, message) end
