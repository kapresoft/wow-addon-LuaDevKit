--- @type string, table
local addon, xns = ...


--- @class LDK_CodeEditor_Namespace
--- @field addon Name
local ns = xns
ns.addon = addon

--- @return LDK_Core_Namespace, LDK_Core_Objects
function ns:cns() return LDK_CORE_NS, LDK_CORE_NS.O end

