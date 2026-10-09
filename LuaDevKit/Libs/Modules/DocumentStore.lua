--- @type LDK_Core_Namespace
local ns = select(2, ...)

--- @class LDK_Document
--- @field name string
--- @field text string

--- @class LDK_DocumentStore
local o = {}; ns.O.DocumentStore = o

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- Looked up per call so a profile switch takes effect.
--- @return LDK_Document[] @The active profile's documents
local function Docs() return ns:p().docs end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- @return number
function o:Count() return #Docs() end

--- @param index number
--- @return LDK_Document? @nil past the last document
function o:Get(index) return Docs()[index] end

--- @param fn fun(index: number, doc: LDK_Document)
function o:Each(fn)
  for index, doc in ipairs(Docs()) do
    fn(index, doc)
  end
end

--- @param name string
--- @param text string
--- @return number @Index of the new document
function o:Add(name, text)
  local docs = Docs()
  docs[#docs + 1] = { name = name, text = text }
  return #docs
end

--- @param index number
--- @param text string
function o:SetText(index, text) Docs()[index].text = text end
