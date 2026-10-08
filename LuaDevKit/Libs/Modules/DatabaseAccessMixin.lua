--- @type LDK_Core_Namespace
local ns = select(2, ...)
local O = ns.O
local AceDB, Database = O.AceDB, O.Database

--[[-----------------------------------------------------------------------------
Types
-------------------------------------------------------------------------------]]
--- @class LDK_DatabaseObj : AceDBObject-3.0
--- @field global LDK_DB_GlobalConfig
--- @field profile LDK_DB_ProfileConfig

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- @class LDK_DatabaseAccessMixin
local o = ns:Register('DatabaseAccessMixin')

--- @class LDK_DatabaseAccess : LDK_DatabaseAccessMixin @An object InitDb mixed these methods into

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- @param self LDK_DatabaseAccess
--- @param db LDK_DatabaseObj
local function RegisterCallbacks(self, db)
  db.RegisterCallback(self, 'OnNewProfile', 'OnNewProfile')
  db.RegisterCallback(self, 'OnProfileChanged', 'OnProfileChanged')
  db.RegisterCallback(self, 'OnProfileCopied', 'OnProfileCopied')
  db.RegisterCallback(self, 'OnProfileReset', 'OnProfileReset')
  db.RegisterCallback(self, 'OnProfileDeleted', 'OnProfileDeleted')
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
function o:OnNewProfile(evt, db, profileKey) end
function o:OnProfileChanged(evt, db, profileKey) end
function o:OnProfileCopied(evt, db, sourceKey) end
function o:OnProfileReset(evt, db) end
function o:OnProfileDeleted(evt, db, profileKey) end

--- Mixes these methods into the addon, then creates the AceDB.
--- @param addon LuaDevKit
function o:InitDb(addon)
  Mixin(addon, o)
  --- @type LDK_DatabaseObj
  local db = AceDB:New(ns.DB_NAME, nil, true)
  db:RegisterDefaults(Database:GetDefaultDatabase())
  RegisterCallbacks(addon, db)
  ns:RegisterDB(db)
end

--- @return LDK_DB_GlobalConfig
function o:g() return ns:db()['global'] end

--- @return LDK_DB_ProfileConfig
function o:p() return ns:db().profile end
