--- @type string, table
local addon, xns = ...

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
