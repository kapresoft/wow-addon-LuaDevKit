--- @type LDK_Core_Namespace
local ns = select(2, ...)
local O = ns.O

--[[-----------------------------------------------------------------------------
Types
-------------------------------------------------------------------------------]]
--- @class LDK_GlobalConfig

--- @class LDK_ProfileConfig

--- @class LDK_DefaultDatabase
--- @field global LDK_GlobalConfig
--- @field profile LDK_ProfileConfig

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- @class LDK_Database
local o = {}; O.Database = o

--- AceDB defaults; registered by DatabaseMixin:InitDb().
--- @return LDK_DefaultDatabase
function o:GetDefaultDatabase() return { ['global'] = {}, profile = {} } end
