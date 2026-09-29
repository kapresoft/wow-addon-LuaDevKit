--- @type LDK_Core_Namespace
local ns = select(2, ...)

--- @class LDK_Document
--- @field name string
--- @field text string

--- @class LDK_DocumentStore
local o = {}; ns.O.DocumentStore = o

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
-- In memory until the saved-variables schema exists.
--- @type LDK_Document[]
local docs = {}

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- @return number
function o:Count() return #docs end

--- @param index number
--- @return LDK_Document? @nil past the last document
function o:Get(index) return docs[index] end

--- @param fn fun(index: number, doc: LDK_Document)
function o:Each(fn)
  for index, doc in ipairs(docs) do
    fn(index, doc)
  end
end

--- @param name string
--- @param text string
--- @return number @Index of the new document
function o:Add(name, text)
  docs[#docs + 1] = { name = name, text = text }
  return #docs
end

--- @param index number
--- @param text string
function o:SetText(index, text) docs[index].text = text end
